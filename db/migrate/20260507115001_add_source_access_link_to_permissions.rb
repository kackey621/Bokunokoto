class AddSourceAccessLinkToPermissions < ActiveRecord::Migration[8.0]
  def change
    add_column :permissions, :source_access_link_id, :bigint

    add_foreign_key :permissions, :access_links, column: :source_access_link_id, on_delete: :nullify
    add_index :permissions, :source_access_link_id
  end
end
