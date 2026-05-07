require "test_helper"
require "minitest/mock"

class Api::V1::ContentsControllerTest < ActionDispatch::IntegrationTest
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

    @c0 = @vault.contents.create!(title: "L0", body: "L0 body", required_level: 0)
    @c3 = @vault.contents.create!(title: "L3", body: "L3 body", required_level: 3)
    @c5 = @vault.contents.create!(title: "L5", body: "L5 body", required_level: 5)
    @c7 = @vault.contents.create!(title: "L7", body: "L7 body", required_level: 7)
  end

  def auth_headers(user, platform: nil)
    headers = { "Authorization" => "Bearer fake_token" }
    headers["X-BK-Platform"] = platform if platform
    headers
  end

  test "owner sees all content in their vault" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      get api_v1_vault_contents_path(vault_id: @vault.id), headers: auth_headers(@owner)
    end

    assert_response :success
    titles = response.parsed_body["contents"].map { |c| c["title"] }
    assert_includes titles, "L0"
    assert_includes titles, "L7"
  end

  test "viewer sees content up to their trust level" do
    @viewer.permissions.create!(vault: @vault, granted_level: 3)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      get api_v1_vault_contents_path(vault_id: @vault.id), headers: auth_headers(@viewer)
    end

    assert_response :success
    titles = response.parsed_body["contents"].map { |c| c["title"] }
    assert_includes titles, "L0"
    assert_includes titles, "L3"
    assert_not_includes titles, "L5"
    assert_not_includes titles, "L7"
  end

  test "web platform caps trust level at L4" do
    @viewer.permissions.create!(vault: @vault, granted_level: 7)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      get api_v1_vault_contents_path(vault_id: @vault.id), headers: auth_headers(@viewer, platform: "web")
    end

    assert_response :success
    titles = response.parsed_body["contents"].map { |c| c["title"] }
    assert_includes titles, "L3"
    assert_not_includes titles, "L5"
    assert_not_includes titles, "L7"
  end

  test "viewer without permission gets 404 on vault" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      get api_v1_vault_contents_path(vault_id: @vault.id), headers: auth_headers(@viewer)
    end

    assert_response :not_found
  end

  test "viewer cannot access content above their level via show" do
    @viewer.permissions.create!(vault: @vault, granted_level: 3)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      get api_v1_content_path(@c5), headers: auth_headers(@viewer)
    end

    assert_response :not_found
  end

  test "viewer can access content at their level via show with body" do
    @viewer.permissions.create!(vault: @vault, granted_level: 3)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @viewer.firebase_uid } do
      get api_v1_content_path(@c3), headers: auth_headers(@viewer)
    end

    assert_response :success
    assert_equal "L3 body", response.parsed_body["content"]["body"]
  end

  test "owner can show their own content" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      get api_v1_content_path(@c7), headers: auth_headers(@owner)
    end

    assert_response :success
    assert_equal "L7 body", response.parsed_body["content"]["body"]
  end

  test "viewing a content creates an audit log" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      assert_difference "AuditLog.count", 1 do
        get api_v1_content_path(@c0), headers: auth_headers(@owner)
      end
    end

    assert_response :success
    log = AuditLog.last
    assert_equal @owner, log.user
    assert_equal @c0, log.content
    assert_equal "view", log.action
  end

  test "404 on show does not create audit log" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      assert_no_difference "AuditLog.count" do
        get api_v1_content_path(0), headers: auth_headers(@owner)
      end
    end

    assert_response :not_found
  end
end
