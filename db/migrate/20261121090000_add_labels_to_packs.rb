# typle-r's packs carry their own category and tags (PackFields); official packs keep theirs from the catalog.
class AddLabelsToPacks < ActiveRecord::Migration[8.1]
  def change
    add_column :packs, :category, :string
    add_column :packs, :tags, :json, default: [], null: false
  end
end
