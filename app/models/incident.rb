class Incident < ApplicationRecord
  TYPES = %w[rapid_access geo_jump gps_denial auth_failure screenshot_attempt].freeze
  SEVERITIES = { low: 0, medium: 1, high: 2, critical: 3 }.freeze

  belongs_to :vault
  belongs_to :user

  validates :incident_type, inclusion: { in: TYPES }
  validates :severity, inclusion: { in: SEVERITIES.values }

  scope :unresolved, -> { where(resolved: false) }
  scope :critical, -> { where(severity: SEVERITIES[:critical]) }
  scope :recent, -> { order(created_at: :desc) }
end
