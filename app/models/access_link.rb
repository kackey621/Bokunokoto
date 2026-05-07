class AccessLink < ApplicationRecord
  belongs_to :vault
  belongs_to :bound_user, class_name: "User", optional: true
  has_many :permissions, foreign_key: :source_access_link_id, dependent: :nullify

  validates :slug, presence: true, uniqueness: true
  validates :vault_id, presence: true
  validates :initial_level, presence: true,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9 }
  validates :max_uses, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :use_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }
  scope :available, -> { active.where("max_uses IS NULL OR use_count < max_uses") }

  before_validation :generate_slug, on: :create

  def expired?
    expires_at.present? && Time.current > expires_at
  end

  def exhausted?
    max_uses.present? && use_count >= max_uses
  end
  alias_method :max_uses_exceeded?, :exhausted?
  alias_method :max_uses_reached?, :exhausted?

  def bound_to_other?(user)
    bound_user_id.present? && bound_user_id != user.id
  end

  def usable_by?(user)
    !expired? && !exhausted? && !bound_to_other?(user)
  end

  def valid_for_handshake?
    !expired? && !exhausted?
  end

  def use!
    increment!(:use_count)
  end

  def claim!(user)
    now = Time.current

    updated_rows = self.class
      .where(id: id)
      .where("expires_at IS NULL OR expires_at >= ?", now)
      .where("max_uses IS NULL OR use_count < max_uses")
      .where("bound_user_id IS NULL OR bound_user_id = ?", user.id)
      .update_all([
        "bound_user_id = COALESCE(bound_user_id, ?), use_count = use_count + 1",
        user.id
      ])

    return false if updated_rows == 0

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
