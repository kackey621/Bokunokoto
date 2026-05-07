class Permission < ApplicationRecord
  STATUSES = %w[active suspended pending].freeze

  belongs_to :vault
  belongs_to :user
  belongs_to :source_access_link, class_name: 'AccessLink', optional: true

  validates :granted_level, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9 }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :vault_id, message: "already has a permission for this vault" }
end
