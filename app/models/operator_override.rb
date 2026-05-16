class OperatorOverride < ApplicationRecord
  DEFAULT_DURATION = 30.minutes

  belongs_to :operator, class_name: "User"
  belongs_to :vault

  validates :reason, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def self.open!(operator:, vault:, reason:, duration: DEFAULT_DURATION)
    create!(
      operator: operator,
      vault: vault,
      reason: reason,
      expires_at: Time.current + duration
    )
  end

  def expired?
    expires_at <= Time.current
  end

  def close!
    update!(expires_at: Time.current)
  end
end
