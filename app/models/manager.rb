class Manager < AdminRecord
  has_secure_password

  ROLES = %w[admin operator].freeze

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :firebase_uid, uniqueness: true, allow_blank: true

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :firebase_uid, with: ->(uid) { uid.presence&.strip }

  def platform_admin?
    role == "admin"
  end

  def platform_operator?
    %w[admin operator].include?(role)
  end
end
