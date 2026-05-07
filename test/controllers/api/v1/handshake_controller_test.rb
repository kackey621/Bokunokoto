require "test_helper"
require "minitest/mock"

class Api::V1::HandshakeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      firebase_uid: "owner_uid",
      email: "owner@example.com",
      display_name: "Owner",
      role: "owner",
      can_create_vault: true
    )
    @vault = @owner.create_vault!(display_name: "Owner Vault")

    @viewer = User.create!(
      firebase_uid: "viewer_uid",
      email: "viewer@example.com",
      display_name: "Viewer",
      role: "viewer"
    )
    @other_viewer = User.create!(
      firebase_uid: "other_uid",
      email: "other@example.com",
      display_name: "Other",
      role: "viewer"
    )

    @link = AccessLink.create!(
      vault: @vault,
      initial_level: 3,
      preset_context: "Co-worker",
      welcome_message: "Welcome!"
    )
  end

  def auth_headers
    { "Authorization" => "Bearer fake_token" }
  end

  test "first user binds and gets permission" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      assert_difference "Permission.count", 1 do
        post api_v1_handshake_path, params: { slug: @link.slug }, headers: auth_headers
      end
    end

    assert_response :success
    body = response.parsed_body
    assert_equal "Welcome!", body["welcome_message"]
    assert_equal 3, body["permission"]["granted_level"]

    @link.reload
    assert_equal @viewer.id, @link.bound_user_id
    assert_equal 1, @link.use_count
  end

  test "second user gets link_already_bound" do
    @link.claim!(@viewer)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @other_viewer.firebase_uid } do
      assert_no_difference "Permission.count" do
        post api_v1_handshake_path, params: { slug: @link.slug }, headers: auth_headers
      end
    end

    assert_response :forbidden
    assert_equal "link_already_bound", response.parsed_body["code"]
  end

  test "expired link returns 422" do
    @link.update!(expires_at: 1.hour.ago)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      post api_v1_handshake_path, params: { slug: @link.slug }, headers: auth_headers
    end

    assert_response :unprocessable_entity
    assert_equal "expired", response.parsed_body["code"]
  end

  test "exhausted link returns 422" do
    @link.update!(max_uses: 1, use_count: 1)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      post api_v1_handshake_path, params: { slug: @link.slug }, headers: auth_headers
    end

    assert_response :unprocessable_entity
    assert_equal "exhausted", response.parsed_body["code"]
  end

  test "unknown slug returns 404" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      post api_v1_handshake_path, params: { slug: "nope" }, headers: auth_headers
    end

    assert_response :not_found
  end

  test "handshake writes audit log" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      assert_difference "AuditLog.count", 1 do
        post api_v1_handshake_path, params: { slug: @link.slug }, headers: auth_headers
      end
    end

    log = AuditLog.last
    assert_equal "handshake", log.action
    assert_equal @viewer.id, log.user_id
  end

  test "re-handshake by bound user does not lower granted_level" do
    @viewer.permissions.create!(vault: @vault, granted_level: 7)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      post api_v1_handshake_path, params: { slug: @link.slug }, headers: auth_headers
    end

    assert_response :success
    assert_equal 7, @viewer.permissions.find_by(vault: @vault).granted_level
  end
end
