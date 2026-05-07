class AccessLink < ApplicationRecord
  belongs_to :vault
  has_many :permissions, foreign_key: :source_access_link_id, dependent: :nullify

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/, message: "only allows lowercase letters, numbers, and dashes" }
  validates :vault_id, presence: true
  validates :initial_level, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 9 }
  validates :max_uses, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :use_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }
  scope :available, -> { active.where("max_uses IS NULL OR use_count < max_uses") }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def max_uses_exceeded?
    max_uses.present? && use_count >= max_uses
  end

  def valid_for_handshake?
    !expired? && !max_uses_exceeded?
  end

  def use!
    increment!(:use_count)
  end
end
