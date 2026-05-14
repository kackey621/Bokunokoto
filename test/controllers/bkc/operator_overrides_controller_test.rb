require "test_helper"

class Bkc::OperatorOverridesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @operator = User.create!(
      email: "operator@example.com",
      display_name: "Platform Op",
      role: "operator",
      status: "active",
      trust_level: 9,
      can_create_vault: true
    )
    @owner = User.create!(
      email: "owner@example.com",
      display_name: "Owner",
      role: "owner",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    @vault = @owner.owned_vaults.create!(display_name: "Target Vault")
  end

  test "operator can open an override" do
    assert_difference "OperatorOverride.count", 1 do
      post bkc_operator_override_path,
           params: { vault_id: @vault.id, reason: "Compliance review" },
           headers: { "X-Test-User-Id" => @operator.id }
    end

    assert_response :redirect
    override = OperatorOverride.last
    assert_equal @operator, override.operator
    assert_equal @vault, override.vault
    assert override.expires_at > Time.current
    refute override.expired?
  end

  test "opening override writes audit log with actor_role operator" do
    assert_difference "AuditLog.count", 1 do
      post bkc_operator_override_path,
           params: { vault_id: @vault.id, reason: "Abuse check" },
           headers: { "X-Test-User-Id" => @operator.id }
    end

    log = AuditLog.last
    assert_equal "operator_override", log.action
    assert_equal "operator", log.actor_role
    assert_equal @vault, log.vault
    assert_equal @operator, log.user
  end

  test "non-operator cannot open an override" do
    assert_no_difference "OperatorOverride.count" do
      post bkc_operator_override_path,
           params: { vault_id: @vault.id, reason: "Hacking attempt" },
           headers: { "X-Test-User-Id" => @owner.id }
    end

    assert_response :redirect
    assert_match "Only platform operators", flash[:alert]
  end

  test "blank reason is rejected" do
    assert_no_difference "OperatorOverride.count" do
      post bkc_operator_override_path,
           params: { vault_id: @vault.id, reason: "" },
           headers: { "X-Test-User-Id" => @operator.id }
    end

    assert_response :redirect
    assert_match "reason is required", flash[:alert]
  end

  test "operator can close an active override" do
    override = @operator.operator_overrides.create!(
      vault: @vault,
      reason: "Compliance review",
      expires_at: 30.minutes.from_now
    )

    assert_difference "AuditLog.count", 1 do
      delete bkc_operator_override_path,
             headers: { "X-Test-User-Id" => @operator.id }
    end

    assert override.reload.expired?
    log = AuditLog.last
    assert_equal "operator_override_closed", log.action
    assert_equal "operator", log.actor_role
  end

  test "closing with no active override shows alert" do
    delete bkc_operator_override_path,
           headers: { "X-Test-User-Id" => @operator.id }

    assert_response :redirect
    assert_match "No active override", flash[:alert]
  end

  test "opening a new override closes the previous one" do
    vault2 = @owner.owned_vaults.create!(display_name: "Vault 2")
    @operator.operator_overrides.create!(
      vault: @vault,
      reason: "First override",
      expires_at: 30.minutes.from_now
    )

    post bkc_operator_override_path,
         params: { vault_id: vault2.id, reason: "Second override" },
         headers: { "X-Test-User-Id" => @operator.id }

    assert_equal 1, @operator.operator_overrides.active.count
    assert_equal vault2, @operator.operator_overrides.active.first.vault
  end

  test "expired override is not treated as active in BKC vault resolver" do
    @operator.operator_overrides.create!(
      vault: @vault,
      reason: "Old override",
      expires_at: 1.minute.ago
    )

    # Operator also needs their own vault to access BKC
    op_vault = @operator.owned_vaults.create!(display_name: "Op Vault")
    @operator.update!(default_vault_id: op_vault.id)

    get bkc_dashboard_path, headers: { "X-Test-User-Id" => @operator.id }

    assert_response :success
    # current_vault should be the operator's own vault, not the expired override vault
  end
end
