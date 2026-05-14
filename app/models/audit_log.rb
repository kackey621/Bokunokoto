class AuditLog < ApplicationRecord
  ACTIONS = %w[view create update delete handshake login profile_update operator_override operator_override_closed].freeze

  belongs_to :vault
  belongs_to :user
  belongs_to :content, optional: true

  validates :vault_id, presence: true
  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :occurred_at, presence: true

  before_update { raise ActiveRecord::ReadOnlyRecord, "AuditLog is immutable" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "AuditLog is immutable" }

  scope :recent, -> { order(occurred_at: :desc) }
  scope :for_vault, ->(vault) { where(vault: vault) }
  scope :for_user, ->(user) { where(user: user) }
end
