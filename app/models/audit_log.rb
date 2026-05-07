class AuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :content, optional: true

  before_update { raise ActiveRecord::ReadOnlyRecord }
  before_destroy { raise ActiveRecord::ReadOnlyRecord }

  validates :action, presence: true
  validates :occurred_at, presence: true
end
