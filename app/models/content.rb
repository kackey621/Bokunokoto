class Content < ApplicationRecord
  belongs_to :vault
  has_many :audit_logs, dependent: :nullify

  # MEDIUM-025: when content is stored as `format=html`, sanitise the body
  # through Rails' built-in safe-list sanitiser so a malicious owner
  # cannot persist `<script>` tags that later render to viewers.
  SAFE_HTML_TAGS = %w[
    a abbr b blockquote br code dd dl dt em h1 h2 h3 h4 h5 h6 hr i img li
    ol p pre q s small span strong sub sup table tbody td tfoot th thead
    tr u ul
  ].freeze
  SAFE_HTML_ATTRS = %w[href src alt title rel target colspan rowspan].freeze

  before_validation :sanitize_html_body

  validates :title, presence: true
  validates :body, presence: true
  validates :required_level, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9 }
  validates :format, inclusion: { in: %w[markdown html text] }

  # Scope to filter content accessible by a specific user in a specific vault.
  # This implements the person-first relationship-based authorization.
  scope :accessible_for, ->(user, vault, platform: nil) {
    return where(vault: vault) if user.vault == vault # Owner sees everything in their vault

    permission = user.permissions.find_by(vault: vault)
    return none unless permission

    user_level = permission.granted_level

    # Cap trust level to L4 for web platform
    user_level = [ user_level, 4 ].min if platform == "web"

    # If no active permission exists and user is not owner, they see nothing
    permission = user.permissions.find_by(vault: vault, status: "active")
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

  private

  def sanitize_html_body
    return unless format == "html" && body.present?
    self.body = Rails::HTML5::SafeListSanitizer.new.sanitize(
      body,
      tags: SAFE_HTML_TAGS,
      attributes: SAFE_HTML_ATTRS
    )
  end
end
