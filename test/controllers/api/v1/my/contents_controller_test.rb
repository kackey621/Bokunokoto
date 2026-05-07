require "test_helper"
require "minitest/mock"

class Api::V1::My::ContentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      firebase_uid: "owner_uid",
      email: "owner@example.com",
      display_name: "Owner",
      role: "owner",
      can_create_vault: true
    )
    @vault = @owner.create_vault!(display_name: "Owner Vault")
    @no_vault_user = User.create!(
      firebase_uid: "novault_uid",
      email: "novault@example.com",
      display_name: "No Vault",
      role: "viewer"
    )
  end

  def auth_headers(user)
    { "Authorization" => "Bearer fake_token" }
  end

  test "lists owner's content" do
    @vault.contents.create!(title: "Own L0", body: "Body", required_level: 0)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      get api_v1_my_contents_path, headers: auth_headers(@owner)
    end

    assert_response :success
    titles = response.parsed_body["contents"].map { |c| c["title"] }
    assert_includes titles, "Own L0"
  end

  test "creates content under owner's vault" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      assert_difference "Content.count", 1 do
        post api_v1_my_contents_path,
             params: { content: { title: "New", body: "New body", required_level: 2, format: "markdown" } },
             headers: auth_headers(@owner)
      end
    end

    assert_response :created
    assert_equal "New", response.parsed_body["content"]["title"]
  end

  test "user without vault is forbidden" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @no_vault_user.firebase_uid } do
      post api_v1_my_contents_path,
           params: { content: { title: "X", body: "X", required_level: 0 } },
           headers: auth_headers(@no_vault_user)
    end

    assert_response :forbidden
  end

  test "updates content" do
    content = @vault.contents.create!(title: "Old", body: "Old body", required_level: 0)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      patch api_v1_my_content_path(content),
            params: { content: { title: "Updated" } },
            headers: auth_headers(@owner)
    end

    assert_response :success
    assert_equal "Updated", content.reload.title
  end

  test "deletes content" do
    content = @vault.contents.create!(title: "Doomed", body: "Body", required_level: 0)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      assert_difference "Content.count", -1 do
        delete api_v1_my_content_path(content), headers: auth_headers(@owner)
      end
    end

    assert_response :success
  end

  test "deletes content even when audit logs reference it" do
    content = @vault.contents.create!(title: "Viewed", body: "Body", required_level: 0)
    log = AuditLog.create!(user: @owner, vault: @vault, content: content, action: "view", occurred_at: Time.current)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      assert_difference "Content.count", -1 do
        delete api_v1_my_content_path(content), headers: auth_headers(@owner)
      end
    end

    assert_response :success
    assert_nil log.reload.content_id
  end

  test "cannot update content from another vault" do
    other_owner = User.create!(
      firebase_uid: "other_uid",
      email: "other@example.com",
      display_name: "Other",
      role: "owner",
      can_create_vault: true
    )
    other_vault = other_owner.create_vault!(display_name: "Other Vault")
    foreign_content = other_vault.contents.create!(title: "Foreign", body: "Body", required_level: 0)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      patch api_v1_my_content_path(foreign_content),
            params: { content: { title: "Hacked" } },
            headers: auth_headers(@owner)
    end

    assert_response :not_found
    assert_equal "Foreign", foreign_content.reload.title
  end
end
