class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :real_name, :string
    add_column :users, :relationship, :string
    add_column :users, :purpose_of_access, :text
    add_column :users, :profile_completed_at, :datetime
    add_column :users, :face_verified_at, :datetime

    add_index :users, :profile_completed_at
  end
end
