class User < ApplicationRecord
  # Platform/Operator roles. Product roles (owner/viewer) are now handled by relationships.
  ROLES = %w[viewer owner operator admin].freeze
  STATUSES = %w[active suspended archived].freeze

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }

  validates :trust_level, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9 }

  validates :can_create_vault, inclusion: [ true, false ]
  validates :bkc_access, inclusion: [ true, false ]
  validates :is_beta_tester, inclusion: [ true, false ]

  validates :firebase_uid, uniqueness: true, allow_blank: true

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :firebase_uid, with: ->(uid) { uid.presence&.strip }

  has_many :owned_vaults, class_name: "Vault", foreign_key: :user_id, dependent: :destroy
  belongs_to :default_vault_record, class_name: "Vault", foreign_key: :default_vault_id, optional: true
  has_many :permissions, dependent: :destroy
  has_many :accessible_vaults, through: :permissions, source: :vault

  def owns?(vault)
    vault&.user_id == id
  end

  def default_vault
    if default_vault_id.present?
      vault = owned_vaults.find_by(id: default_vault_id)
      return vault if vault && !vault.archived?
    end
    owned_vaults.active.first || owned_vaults.first
  end

  # Deprecated: delegates to default_vault for one-release compatibility.
  def vault
    Rails.logger.warn "DEPRECATION WARNING: User#vault is deprecated. Use User#default_vault or User#owned_vaults."
    default_vault
  end

  # Deprecated compatibility writer used by create_vault! in tests.
  def build_vault(attrs = {})
    owned_vaults.build(attrs)
  end

  def create_vault!(attrs = {})
    owned_vaults.create!(attrs)
  end

  def trust_level_for(vault)
    return 9 if owns?(vault)

    permissions.find_by(vault: vault, status: "active")&.granted_level || 0
  end

  def receive_only?
    owned_vaults.empty?
  end

  def platform_admin?
    role == "admin"
  end

  def platform_operator?
    %w[admin operator].include?(role)
  end
end
