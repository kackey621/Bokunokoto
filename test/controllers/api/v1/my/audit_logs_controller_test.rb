require "test_helper"
require "minitest/mock"

class Api::V1::My::AuditLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      firebase_uid: "owner_uid",
      email: "owner@example.com",
      display_name: "Owner",
      role: "owner",
      can_create_vault: true
    )
    @vault = @owner.create_vault!(display_name: "Vault")
    @viewer = User.create!(
      firebase_uid: "viewer_uid",
      email: "viewer@example.com",
      display_name: "Viewer",
      role: "viewer"
    )
  end

  def auth_headers
    { "Authorization" => "Bearer fake_token" }
  end

  test "owner sees their vault's audit logs" do
    AuditLog.create!(vault: @vault, user: @viewer, action: "view", occurred_at: Time.current)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      get api_v1_my_audit_logs_path, headers: auth_headers
    end

    assert_response :success
    logs = response.parsed_body["audit_logs"]
    assert_equal 1, logs.length
    assert_equal "view", logs.first["action"]
  end

  test "logs are scoped to the caller's vault only" do
    other_vault = User.create!(email: "x@y.com", display_name: "Other", role: "owner").create_vault!(display_name: "Other")
    AuditLog.create!(vault: other_vault, user: @owner, action: "view", occurred_at: Time.current)
    AuditLog.create!(vault: @vault, user: @viewer, action: "view", occurred_at: Time.current)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      get api_v1_my_audit_logs_path, headers: auth_headers
    end

    logs = response.parsed_body["audit_logs"]
    assert_equal 1, logs.length
  end

  test "user without vault is forbidden" do
    no_vault = User.create!(firebase_uid: "nv_uid", email: "nv@example.com", display_name: "NV", role: "viewer")

    FirebaseIdToken::Signature.stub :verify, { "sub" => no_vault.firebase_uid } do
      get api_v1_my_audit_logs_path, headers: auth_headers
    end

    assert_response :forbidden
  end

  test "viewing content writes an audit log" do
    @viewer.permissions.create!(vault: @vault, granted_level: 5)
    content = @vault.contents.create!(title: "Secret", body: "Body", required_level: 3)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      assert_difference "AuditLog.count", 1 do
        get api_v1_content_path(content), headers: auth_headers
      end
    end

    log = AuditLog.last
    assert_equal "view", log.action
    assert_equal @viewer.id, log.user_id
    assert_equal content.id, log.content_id
  end
end
