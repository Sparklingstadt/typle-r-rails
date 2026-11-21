# The official packs: the lists of typle-r (db/official_lists, in the order of manifest.json), with a pack for each
# group and for each list without one. A pack's catalog id is "pack-" and the id of its first list, as in typle-r.
module OfficialCatalog
  DIRECTORY = Rails.root.join("db/official_lists")

  OfficialList = Data.define(:id, :name, :category, :tags, :level, :writing_language, :words) do
    def word_count = words.size
  end

  OfficialPack = Data.define(:catalog_id, :name, :category, :tags, :lists) do
    def word_count = lists.sum(&:word_count)
    def first_words(count = 3) = lists.first.words.first(count)
  end

  module_function

  def packs
    @packs ||= load_packs
  end

  def find(catalog_id) = packs.find { |pack| pack.catalog_id == catalog_id }

  def find_list(list_id)
    packs.each do |pack|
      list = pack.lists.find { |item| item.id == list_id }
      return [pack, list] if list
    end
    nil
  end

  def categories = packs.map(&:category).compact.uniq

  # The description written for an official pack's own page (typle-r's src/lib/packs/pages.json), when it has one.
  def description(catalog_id)
    @descriptions ||= JSON.parse(Rails.root.join("db/official_pages.json").read).to_h { |page| [page["catalogId"], page["description"]] }
    @descriptions[catalog_id]
  end

  # Copies an official pack into the user's library. Following again does nothing.
  def follow(user, catalog_id)
    official = find(catalog_id) or raise ActiveRecord::RecordNotFound
    user.packs.find_by(catalog_id:) || Pack.transaction do
      # A pack of the user with the same name keeps it; the followed one is told apart with （2）, as typle-r does.
      pack = user.packs.create!(name: PackFile.unique_pack_name(user, official.name), catalog_id:)
      official.lists.each do |list|
        pack.word_lists.create!(
          user:, name: list.name, category: official.category, level: list.level, origin_list_id: list.id, writing_language: list.writing_language,
          words: list.words.each_with_index.map { |word, index| Word.new(**word, position: index) }
        )
      end
      pack
    end
  end

  def load_packs
    order = JSON.parse(DIRECTORY.join("manifest.json").read)
    lists = order.map { |file| JSON.parse(DIRECTORY.join(file).read) }
    seen = Hash.new(0)
    packs = lists.group_by { |list| list["group"].presence || "list:#{list["id"]}" }.map do |key, members|
      first = members.first
      OfficialPack.new(
        catalog_id: "pack-#{first["id"]}",
        name: unique_name(key.start_with?("list:") ? first["name"] : key, seen),
        category: first["category"],
        tags: members.flat_map { |list| list["tags"] || [] }.uniq,
        lists: members.map { |list|
          OfficialList.new(
            id: list["id"], name: list["name"], category: list["category"], tags: list["tags"] || [],
            level: Array(list["levels"]).join(" "),
            writing_language: list.dig("writing", "language"),
            words: list["words"].map { |word|
              { display: word["display"], input: word["input"], annotation: word["annotation"].to_s, input_type: word["input_type"] }
            }
          )
        }
      )
    end
    packs
  end

  # typle-r's convertLibrary names a second pack of the same name "名前（2）".
  def unique_name(name, seen)
    seen[name] += 1
    seen[name] == 1 ? name : "#{name}（#{seen[name]}）"
  end
end
