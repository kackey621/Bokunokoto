class CreateAccessLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :access_links do |t|
      t.references :vault, null: false, foreign_key: true
      t.string :slug, null: false
      t.integer :initial_level, default: 0
      t.text :welcome_message
      t.json :preset_context, default: {}
      t.datetime :expires_at
      t.integer :max_uses
      t.integer :use_count, default: 0
      t.timestamps
    end

    add_index :access_links, :slug, unique: true
    add_index :access_links, :vault_id
    add_index :access_links, :expires_at
  end
end
