class Vault < ApplicationRecord
  belongs_to :user
  belongs_to :owner, class_name: "User", foreign_key: :user_id

  KINDS = %w[personal shared].freeze

  validates :display_name, presence: true
  validates :kind, inclusion: { in: KINDS }

  has_many :permissions, dependent: :destroy
  has_many :viewers, through: :permissions, source: :user
  has_many :contents, dependent: :destroy
  has_many :access_links, dependent: :destroy
  has_many :audit_logs, dependent: :delete_all
  has_many :greetings, dependent: :destroy
  has_many :incidents, dependent: :destroy

  encrypts :bank_account_info, deterministic: false

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  def bank_account_data
    return nil if bank_account_info.blank?
    JSON.parse(bank_account_info) rescue nil
  end

  def bank_account_data=(data)
    self.bank_account_info = data.present? ? data.to_json : nil
  end

  def masked_account_number
    return nil unless bank_account_data
    account = bank_account_data["account_number"]
    return nil if account.blank?

    if account.length > 7
      first = account[0..2]
      last = account[-4..-1]
      "#{first}-****-#{last}"
    else
      "*" * (account.length - 4) + account[-4..-1]
    end
  end
end
