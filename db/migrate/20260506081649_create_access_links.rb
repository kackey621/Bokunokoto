class CreateAccessLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :access_links do |t|
      t.string :slug, null: false
      t.references :vault, null: false, foreign_key: true
      t.text :preset_context
      t.integer :initial_level, default: 0, null: false
      t.text :welcome_message
      t.datetime :expires_at
      t.integer :max_uses
      t.integer :use_count, default: 0, null: false
      t.references :bound_user, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :access_links, :slug, unique: true
  end
end
