require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      firebase_uid: "audit_user_uid",
      email: "audit@example.com",
      display_name: "Audit User",
      role: "viewer"
    )
    @vault = Vault.create!(user: @user, display_name: "Audit Vault")
    @content = @vault.contents.create!(title: "Audit Content", body: "Body", required_level: 0)
  end

  test "can be created" do
    log = AuditLog.create!(user: @user, content: @content, action: "view", occurred_at: Time.current)
    assert log.persisted?
  end

  test "cannot be updated" do
    log = AuditLog.create!(user: @user, content: @content, action: "view", occurred_at: Time.current)
    assert_raises(ActiveRecord::ReadOnlyRecord) { log.update!(action: "edit") }
  end

  test "cannot be destroyed" do
    log = AuditLog.create!(user: @user, content: @content, action: "view", occurred_at: Time.current)
    assert_raises(ActiveRecord::ReadOnlyRecord) { log.destroy! }
  end

  test "requires action" do
    log = AuditLog.new(user: @user, content: @content, occurred_at: Time.current)
    assert_not log.valid?
    assert_includes log.errors[:action], "can't be blank"
  end
end
