class CreateContents < ActiveRecord::Migration[8.1]
  def change
    create_table :contents do |t|
      t.references :vault, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false
      t.integer :required_level, null: false, default: 0
      t.string :symbol_type
      t.string :format, null: false, default: "markdown"
      t.json :permitted_user_ids

      t.timestamps
    end
  end
end
