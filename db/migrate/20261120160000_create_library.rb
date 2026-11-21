class CreateLibrary < ActiveRecord::Migration[8.1]
  def change
    create_table :packs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      # Set on a pack followed from the official catalog; such a pack is kept equal to the catalog and is read-only.
      t.string :catalog_id
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :packs, [:user_id, :catalog_id], unique: true

    create_table :word_lists do |t|
      t.references :pack, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :category
      t.string :level
      # The id of the official list a followed list was copied from.
      t.string :origin_list_id
      t.integer :position, null: false, default: 0
      # The last finished practice of the list's weak words alone (see WeakWords).
      t.datetime :weak_reviewed_at
      t.json :weak_review_missed, null: false, default: []
      t.timestamps
    end

    create_table :words do |t|
      t.references :word_list, null: false, foreign_key: true
      t.string :display, null: false
      t.string :input, null: false
      t.string :annotation, null: false, default: ""
      t.string :input_type
      t.integer :position, null: false, default: 0
    end

    create_table :practice_records do |t|
      t.references :user, null: false, foreign_key: true
      t.references :word_list, null: false, foreign_key: true
      t.integer :time_ms, null: false
      t.integer :mistakes, null: false, default: 0
      t.decimal :accuracy, precision: 5, scale: 2, null: false
      t.integer :word_count, null: false
      # nil for normal typing, "recall" for 思い出して打つ.
      t.string :mode
      t.json :missed, null: false, default: []
      t.datetime :practiced_at, null: false
      t.timestamps
    end
    add_index :practice_records, [:user_id, :practiced_at]
  end
end
