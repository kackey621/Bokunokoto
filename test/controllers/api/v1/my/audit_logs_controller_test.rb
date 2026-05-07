require "test_helper"
require "minitest/mock"

class Api::V1::My::AuditLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      firebase_uid: "audit_owner_uid",
      email: "audit_owner@example.com",
      display_name: "Audit Owner",
      role: "owner",
      can_create_vault: true
    )
    @vault = @owner.create_vault!(display_name: "Audit Owner Vault")
    @content = @vault.contents.create!(title: "Logged Content", body: "Body", required_level: 0)

    @no_vault_user = User.create!(
      firebase_uid: "audit_novault_uid",
      email: "audit_novault@example.com",
      display_name: "No Vault",
      role: "viewer"
    )
  end

  def auth_headers
    { "Authorization" => "Bearer fake_token" }
  end

  test "returns audit logs for vault owner" do
    AuditLog.create!(user: @owner, content: @content, action: "view", occurred_at: Time.current)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      get api_v1_my_audit_logs_path, headers: auth_headers
    end

    assert_response :success
    logs = response.parsed_body["audit_logs"]
    assert_equal 1, logs.length
    assert_equal @content.id, logs.first["content_id"]
    assert_equal "view", logs.first["action"]
  end

  test "returns empty list when no logs exist" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      get api_v1_my_audit_logs_path, headers: auth_headers
    end

    assert_response :success
    assert_equal [], response.parsed_body["audit_logs"]
  end

  test "returns 404 for user without vault" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @no_vault_user.firebase_uid } do
      get api_v1_my_audit_logs_path, headers: auth_headers
    end

    assert_response :not_found
  end

  test "does not return logs from other vaults" do
    other_owner = User.create!(
      firebase_uid: "other_audit_uid",
      email: "other_audit@example.com",
      display_name: "Other",
      role: "owner",
      can_create_vault: true
    )
    other_vault = other_owner.create_vault!(display_name: "Other Vault")
    other_content = other_vault.contents.create!(title: "Other", body: "Body", required_level: 0)
    AuditLog.create!(user: @owner, content: other_content, action: "view", occurred_at: Time.current)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      get api_v1_my_audit_logs_path, headers: auth_headers
    end

    assert_response :success
    assert_equal [], response.parsed_body["audit_logs"]
  end
end
