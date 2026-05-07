class AuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :content

  before_update { raise ActiveRecord::ReadOnlyRecord }
  before_destroy { raise ActiveRecord::ReadOnlyRecord }

  validates :action, presence: true
  validates :occurred_at, presence: true
end
