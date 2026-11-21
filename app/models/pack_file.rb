# typle-r's pack file (`<pack name>.typle-pack.json`, src/lib/packFile.ts): a pack and its lists to hand to another
# account, without records, ids, dates or origin.
module PackFile
  FORMAT = "typle-pack"

  class Unreadable < StandardError; end

  module_function

  # The file's text: keys in typle-r's order, two-space indents and a newline at the end. Empty optional fields are left out.
  def encode(pack)
    meta = { name: pack.name }
    meta[:description] = pack.description if pack.description.present?
    meta[:category] = pack.category if pack.category.present?
    meta[:tags] = pack.tags if pack.tags.any?
    lists = pack.word_lists.map do |list|
      item = { name: list.name }
      item[:levels] = [list.level] if list.level.present?
      item[:writing] = { language: list.writing_language } if list.writing_language.present?
      item[:words] = list.words.map { |word|
        { display: word.display, input: word.input, annotation: word.annotation }.tap { |w| w[:input_type] = word.input_type if word.input_type }
      }
      item
    end
    JSON.pretty_generate({ format: FORMAT, version: 1, pack: meta, lists: }) + "\n"
  end

  # The pack of a file, added after the user's other packs. Only the shape is checked here; the lists are checked as a save
  # checks them (RecordInvalid). A name a pack already has gets （2）, （3）…
  def import(user, text)
    data = JSON.parse(text) rescue raise(Unreadable)
    raise Unreadable unless data.is_a?(Hash) && data["format"] == FORMAT && data["version"] == 1 && data["pack"].is_a?(Hash) &&
      data["lists"].is_a?(Array) && data["lists"].any?
    meta = data["pack"]
    raise Unreadable unless meta["name"].is_a?(String) && optional_string?(meta["description"])
    lists = data["lists"].map do |item|
      raise Unreadable unless item.is_a?(Hash) && item["name"].is_a?(String) && item["words"].is_a?(Array) &&
        (item["levels"].nil? || (item["levels"].is_a?(Array) && item["levels"].all?(String))) &&
        (item["writing"].nil? || (item["writing"].is_a?(Hash) && item["writing"].keys == ["language"] && item["writing"]["language"].in?(WordList::WRITING_LANGUAGES)))
      words = item["words"].map do |word|
        raise Unreadable unless word.is_a?(Hash) && %w[display input annotation].all? { |key| word[key].is_a?(String) } &&
          (word["input_type"].nil? || word["input_type"].in?(Word::INPUT_TYPES))
        word.slice("display", "input", "annotation", "input_type")
      end
      { name: item["name"].strip, level: Array(item["levels"]).map(&:strip).compact_blank.first, writing_language: item.dig("writing", "language"), words: }
    end
    Pack.transaction do
      pack = user.packs.create!(name: unique_pack_name(user, meta["name"].strip), description: meta["description"].to_s.strip.presence,
        category: meta["category"].is_a?(String) ? meta["category"] : nil, tags: meta["tags"].is_a?(Array) ? meta["tags"].grep(String) : [])
      lists.each { |item| add_list(pack, item) }
      pack
    end
  end

  # typle-r's copyPack: the pack and its lists without records or origin, named with （コピー）, （コピー2）…
  def copy(pack, suffix)
    Pack.transaction do
      taken = pack.user.packs.pluck(:name)
      copy = pack.user.packs.create!(name: copy_name(taken, pack.name, suffix), description: pack.description, category: pack.category, tags: pack.tags)
      pack.word_lists.each do |list|
        add_list(copy, { name: list.name, level: list.level, writing_language: list.writing_language, category: list.category,
          words: list.words.map { |word| word.attributes.slice("display", "input", "annotation", "input_type") } })
      end
      copy
    end
  end

  # typle-r's duplicateList: a copy of the list at the end of its pack, without records, named apart from the pack's lists.
  def copy_list(list, suffix)
    copy = list.pack.word_lists.new(user: list.user, name: copy_name(list.pack.word_lists.map(&:name), list.name, suffix),
      category: list.category, writing_language: list.writing_language)
    copy.words_rows = list.words.map { |word| word.attributes.slice("display", "input", "annotation", "input_type") }
    copy.save!
    copy
  end

  # copyName: the first of name + suffix(1), name + suffix(2)… that no other name has (case aside).
  def copy_name(names, name, suffix)
    taken = names.map { |taken_name| taken_name.strip.downcase }.to_set
    (1..).each do |n|
      mark = suffix.(n)
      candidate = "#{name.strip[0, 200 - mark.length]}#{mark}"
      return candidate unless taken.include?(candidate.downcase)
    end
  end

  def unique_pack_name(user, name)
    taken = user.packs.pluck(:name).map(&:downcase).to_set
    return name unless taken.include?(name.downcase)
    (2..).each { |n| candidate = "#{name}（#{n}）"; return candidate unless taken.include?(candidate.downcase) }
  end

  def add_list(pack, item)
    list = pack.word_lists.new(user: pack.user, name: item[:name], level: item[:level], writing_language: item[:writing_language], category: item[:category])
    list.words_rows = item[:words]
    list.save!
  end

  def optional_string?(value) = value.nil? || value.is_a?(String)
end
