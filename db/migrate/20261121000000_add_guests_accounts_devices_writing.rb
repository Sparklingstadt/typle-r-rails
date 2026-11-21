class AddGuestsAccountsDevicesWriting < ActiveRecord::Migration[8.1]
  def change
    # A guest is a user without a login: its data is tied to one browser by a cookie, as typle-r keeps it in that
    # browser's storage, and is kept apart from any account.
    add_column :users, :guest, :boolean, null: false, default: false
    change_column_null :users, :login_id, true
    change_column_null :users, :password_digest, true
    add_column :users, :email, :string
    add_column :users, :email_confirmed_at, :datetime
    add_index :users, :email, unique: true
    add_column :users, :github_uid, :string
    add_column :users, :github_login, :string
    add_index :users, :github_uid, unique: true
    # nil until saved: every interest (see Interests::DEFAULT).
    add_column :users, :interests, :json

    create_table :devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :layout, null: false, default: ""
      t.timestamps
    end

    # The device a run was practised on, as it was then: "default" for the built-in device or a device's id.
    # Left out (nil) when no device was chosen (未選択).
    add_column :practice_records, :device_key, :string
    add_column :practice_records, :device_name, :string
    add_column :practice_records, :device_layout, :string

    # The language of a list marked for handwriting (Typle Handwriting); nil when it is not marked.
    add_column :word_lists, :writing_language, :string
  end
end
