class AccessLink < ApplicationRecord
  belongs_to :vault
  belongs_to :bound_user, class_name: "User", optional: true

  validates :slug, presence: true, uniqueness: true
  validates :initial_level, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9 }
  validates :max_uses, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :use_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :generate_slug, on: :create

  def expired?
    expires_at.present? && Time.current > expires_at
  end

  def exhausted?
    max_uses.present? && use_count >= max_uses
  end

  def bound_to_other?(user)
    bound_user_id.present? && bound_user_id != user.id
  end

  def usable_by?(user)
    !expired? && !exhausted? && !bound_to_other?(user)
  end

  def claim!(user)
    return false unless usable_by?(user)

    transaction do
      update_columns(bound_user_id: user.id) if bound_user_id.nil?
      update_columns(use_count: use_count + 1)
    end
    reload
    true
  end

  private

  def generate_slug
    self.slug ||= loop do
      candidate = SecureRandom.urlsafe_base64(12)
      break candidate unless AccessLink.exists?(slug: candidate)
    end
  end
end
