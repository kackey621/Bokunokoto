class OperatorOverride < ApplicationRecord
  belongs_to :operator, class_name: "User"
  belongs_to :vault

  validates :reason, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def expired?
    expires_at <= Time.current
  end

  def close!
    update!(expires_at: Time.current)
  end
end
