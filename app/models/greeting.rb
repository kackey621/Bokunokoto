class Greeting < ApplicationRecord
  ANIMATION_TYPES = %w[fade slide zoom bounce].freeze

  belongs_to :vault
  belongs_to :recipient_user, class_name: "User"

  validates :content, presence: true
  validates :scheduled_delivery_time, presence: true
  validates :unlock_animation_type, inclusion: { in: ANIMATION_TYPES }
  validate :scheduled_time_in_future

  scope :scheduled, -> { where('scheduled_delivery_time > ?', Time.current) }
  scope :unlocked, -> { where.not(unlocked_at: nil) }
  scope :locked, -> { where(unlocked_at: nil) }
  scope :ready_to_unlock, -> { locked.where('scheduled_delivery_time <= ?', Time.current) }

  def locked?
    unlocked_at.nil?
  end

  def ready_to_unlock?
    locked? && scheduled_delivery_time <= Time.current
  end

  def unlock!
    update(unlocked_at: Time.current)
  end

  private

  def scheduled_time_in_future
    return if scheduled_delivery_time.blank?
    if scheduled_delivery_time <= Time.current
      errors.add(:scheduled_delivery_time, "must be in the future")
    end
  end
end
