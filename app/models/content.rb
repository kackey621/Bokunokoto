class Content < ApplicationRecord
  belongs_to :vault

  validates :title, presence: true
  validates :body, presence: true
  validates :required_level, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9 }
  validates :format, inclusion: { in: %w[markdown html text] }

  # Scope to filter content accessible by a specific user in a specific vault.
  # This implements the person-first relationship-based authorization.
  scope :accessible_for, ->(user, vault, platform: nil) {
    return where(vault: vault) if user.vault == vault # Owner sees everything in their vault

    user_level = user.trust_level_for(vault)

    # Cap trust level to L4 for web platform
    user_level = [ user_level, 4 ].min if platform == "web"

    # If no permission exists and user is not owner, they see nothing
    permission = user.permissions.find_by(vault: vault)
    return none unless permission

    if ActiveRecord::Base.connection.adapter_name == "SQLite"
      where(vault: vault).where(
        "required_level <= :level OR EXISTS (SELECT 1 FROM json_each(permitted_user_ids) WHERE value = :user_id)",
        level: user_level,
        user_id: user.id
      )
    else
      where(vault: vault).where(
        "required_level <= :level OR JSON_CONTAINS(permitted_user_ids, :user_id)",
        level: user_level,
        user_id: user.id.to_s
      )
    end
  }
end
