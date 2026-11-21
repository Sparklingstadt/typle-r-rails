# What a user is interested in, which picks the official packs shown first. As typle-r's src/lib/interests.ts: a parent
# is a category; its children are tags. A user who has saved none is interested in everything.
module Interests
  Option = Data.define(:id, :category, :children)
  Child = Data.define(:id, :tag)

  def self.child(parent, name, tag) = Child.new(id: "#{parent}/#{name}", tag:)

  OPTIONS = [
    Option.new(id: "language", category: "語学", children: [
      child("language", "zh", "中国語"), child("language", "ru", "ロシア語"), child("language", "ko", "韓国語"),
      child("language", "en", "英語"), child("language", "es", "スペイン語"), child("language", "fr", "フランス語"),
      child("language", "de", "ドイツ語"), child("language", "cs", "チェコ語")
    ]),
    Option.new(id: "programming", category: "プログラミング", children: [
      child("programming", "go", "Go"), child("programming", "kotlin", "Kotlin"), child("programming", "java", "Java"),
      child("programming", "typescript", "TypeScript"), child("programming", "php", "PHP"), child("programming", "ruby", "Ruby"),
      child("programming", "sql", "SQL"), child("programming", "linux", "Linux"), child("programming", "vim", "Vim"),
      child("programming", "test", "テスト"), child("programming", "node", "Node.js"), child("programming", "shell", "シェル"),
      child("programming", "cloud", "クラウド")
    ])
  ].freeze

  KNOWN = OPTIONS.flat_map { |option| [option.id, *option.children.map(&:id)] }.freeze
  DEFAULT = KNOWN

  module_function

  def decode(value) = value.nil? ? DEFAULT.dup : Array(value).map(&:to_s) & KNOWN

  # Known ids in the order of the options; a child only under a chosen parent.
  # typle-r's toggleInterest: a parent switches with its children; a child only switches under a chosen parent.
  def toggle(ids, id)
    ids = Array(ids).map(&:to_s)
    if (parent = OPTIONS.find { |option| option.id == id })
      return normalize(ids + [id]) unless ids.include?(id)
      children = parent.children.map(&:id)
      return normalize(ids.reject { |item| item == id || children.include?(item) })
    end
    owner = OPTIONS.find { |option| option.children.any? { |child| child.id == id } }
    return normalize(ids) if owner && !ids.include?(owner.id)
    normalize(ids.include?(id) ? ids - [id] : ids + [id])
  end

  def normalize(ids)
    chosen = Array(ids).map(&:to_s).to_set
    OPTIONS.flat_map { |option|
      next [] unless chosen.include?(option.id)
      [option.id, *option.children.map(&:id).select { |id| chosen.include?(id) }]
    }
  end

  # Whether a pack fits: its category is a chosen parent, and it has a chosen child's tag when any child is chosen.
  def matches?(pack, ids)
    tags = pack.tags.map(&:downcase).to_set
    OPTIONS.any? do |option|
      next false unless ids.include?(option.id) && option.category == pack.category
      chosen = option.children.select { |child| ids.include?(child.id) }
      chosen.empty? || chosen.any? { |child| tags.include?(child.tag.downcase) }
    end
  end
end
