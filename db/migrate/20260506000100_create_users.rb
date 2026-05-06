class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :firebase_uid
      t.string :email, null: false
      t.string :display_name, null: false
      t.string :role, null: false, default: "viewer"
      t.string :status, null: false, default: "active"
      t.integer :trust_level, null: false, default: 0
      t.text :notes
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :users, :firebase_uid, unique: true
    add_index :users, :email, unique: true
    add_index :users, :role
    add_index :users, :status
  end
end
