require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "owner@example.com", display_name: "Owner", role: "owner")
    @vault = @owner.create_vault!(display_name: "Vault")
    @log = AuditLog.create!(
      vault: @vault,
      user: @owner,
      action: "view",
      occurred_at: Time.current
    )
  end

  test "is created successfully with valid attributes" do
    assert @log.persisted?
  end

  test "raises ReadOnlyRecord on update" do
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      @log.update!(action: "delete")
    end
  end

  test "raises ReadOnlyRecord on destroy" do
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      @log.destroy!
    end
  end

  test "validates action in allowed list" do
    log = AuditLog.new(vault: @vault, user: @owner, action: "rogue", occurred_at: Time.current)
    assert_not log.valid?
    assert_includes log.errors[:action], "is not included in the list"
  end

  test "for_vault scope filters by vault" do
    other_vault = User.create!(email: "x@y.com", display_name: "X", role: "owner").create_vault!(display_name: "Other")
    AuditLog.create!(vault: other_vault, user: @owner, action: "view", occurred_at: Time.current)

    assert_equal 1, AuditLog.for_vault(@vault).count
    assert_equal 1, AuditLog.for_vault(other_vault).count
  end

  test "recent scope orders by occurred_at desc" do
    older = AuditLog.create!(vault: @vault, user: @owner, action: "view", occurred_at: 1.hour.ago)
    newer = AuditLog.create!(vault: @vault, user: @owner, action: "view", occurred_at: 1.second.from_now)

    ordered = AuditLog.for_vault(@vault).recent.to_a
    assert_equal newer.id, ordered.first.id
    assert_equal older.id, ordered.last.id
  end

  # MEDIUM-022
  test "validates actor_role against ACTOR_ROLES" do
    bad = AuditLog.new(vault: @vault, user: @owner, action: "view",
                       occurred_at: Time.current, actor_role: "wizard")
    assert_not bad.valid?
    assert_includes bad.errors[:actor_role], "is not included in the list"
  end

  test "accepts any role in ACTOR_ROLES" do
    AuditLog::ACTOR_ROLES.each do |role|
      log = AuditLog.create!(vault: @vault, user: @owner, action: "view",
                             occurred_at: Time.current, actor_role: role)
      assert log.persisted?, "expected #{role.inspect} to pass actor_role validation"
    end
  end

  test "allows nil actor_role for legacy rows" do
    log = AuditLog.create!(vault: @vault, user: @owner, action: "view",
                           occurred_at: Time.current, actor_role: nil)
    assert log.persisted?
  end
end
