class User < ApplicationRecord
  # Platform/Operator roles. Product roles (owner/viewer) are now handled by relationships.
  ROLES = %w[viewer owner operator admin].freeze
  STATUSES = %w[active suspended archived].freeze

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }

  # Temporary compatibility data until per-vault permissions own trust.
  validates :trust_level, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9 }

  # Account capabilities
  validates :can_create_vault, inclusion: [ true, false ]
  validates :bkc_access, inclusion: [ true, false ]
  validates :is_beta_tester, inclusion: [ true, false ]

  validates :firebase_uid, uniqueness: true, allow_blank: true

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :firebase_uid, with: ->(uid) { uid.presence&.strip }

  has_one :vault, dependent: :destroy
  has_many :permissions, dependent: :destroy
  has_many :accessible_vaults, through: :permissions, source: :vault

  def trust_level_for(vault)
    return 9 if self.vault == vault # Owner has max trust for their own vault

    permissions.find_by(vault: vault, status: "active")&.granted_level || 0
  end

  def receive_only?
    vault.nil?
  end

  def platform_admin?
    role == "admin"
  end

  def platform_operator?
    %w[admin operator].include?(role)
  end
end
