class Vault < ApplicationRecord
  belongs_to :user

  validates :display_name, presence: true
  validates :user_id, uniqueness: true

  has_many :permissions, dependent: :destroy
  has_many :viewers, through: :permissions, source: :user
  has_many :contents, dependent: :destroy
end
