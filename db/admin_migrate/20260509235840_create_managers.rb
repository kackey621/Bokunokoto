class CreateManagers < ActiveRecord::Migration[8.1]
  def change
    create_table :managers do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :firebase_uid
      t.string :role, default: "admin", null: false

      t.timestamps
    end
    add_index :managers, :email, unique: true
    add_index :managers, :firebase_uid, unique: true
  end
end
