class CreateGreetings < ActiveRecord::Migration[8.0]
  def change
    create_table :greetings do |t|
      t.references :vault, null: false, foreign_key: true
      t.references :recipient_user, foreign_key: { to_table: :users }
      t.text :content
      t.datetime :scheduled_delivery_time
      t.datetime :unlocked_at
      t.string :unlock_animation_type, default: 'fade'
      t.timestamps
    end

    add_index :greetings, :scheduled_delivery_time
    add_index :greetings, :unlocked_at
  end
end
