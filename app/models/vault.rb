class Vault < ApplicationRecord
  belongs_to :user

  validates :display_name, presence: true
  validates :user_id, uniqueness: true

  has_many :permissions, dependent: :destroy
  has_many :viewers, through: :permissions, source: :user
  has_many :contents, dependent: :destroy
  has_many :access_links, dependent: :destroy
  # AuditLog is immutable at the model layer (raises on destroy via callback);
  # use :delete_all so cascade purge bypasses the hook intended for app code.
  has_many :audit_logs, dependent: :delete_all
  has_many :greetings, dependent: :destroy
  has_many :incidents, dependent: :destroy

  encrypts :bank_account_info, deterministic: false

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

    # Show first 3 and last 4 digits, mask the rest
    if account.length > 7
      first = account[0..2]
      last = account[-4..-1]
      "#{first}-****-#{last}"
    else
      "*" * (account.length - 4) + account[-4..-1]
    end
  end
end
