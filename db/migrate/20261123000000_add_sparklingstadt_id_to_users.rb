# Sparklingstadt ID: the sub an account signs in with (typle-r's typle_sid_links, or its own account sid:<sub>), and the
# name the ID gives an account it made. The columns of the ID-and-password login stay, as typle-r keeps those accounts.
class AddSparklingstadtIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :sid_sub, :string
    add_index :users, :sid_sub, unique: true
    add_column :users, :name, :string
  end
end
