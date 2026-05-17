class AuditLog < ApplicationRecord
  ACTIONS = %w[view create update delete handshake login profile_update operator_override operator_override_closed].freeze
  # MEDIUM-022: `actor_role` was a free-text column with an index but no
  # inclusion validation, so callers could write arbitrary strings into
  # what is supposed to be the privilege snapshot at write time.
  ACTOR_ROLES = %w[user viewer operator admin system].freeze

  belongs_to :vault
  belongs_to :user
  belongs_to :content, optional: true

  validates :vault_id, presence: true
  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :occurred_at, presence: true
  # `allow_nil: true` because legacy rows pre-date the snapshot column.
  validates :actor_role, inclusion: { in: ACTOR_ROLES }, allow_nil: true

  before_update { raise ActiveRecord::ReadOnlyRecord, "AuditLog is immutable" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "AuditLog is immutable" }

  scope :recent, -> { order(occurred_at: :desc) }
  scope :for_vault, ->(vault) { where(vault: vault) }
  scope :for_user, ->(user) { where(user: user) }
end
