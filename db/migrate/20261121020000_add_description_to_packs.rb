class AddDescriptionToPacks < ActiveRecord::Migration[8.1]
  def change
    add_column :packs, :description, :text
  end
end
