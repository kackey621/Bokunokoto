require "test_helper"
require "minitest/mock"

class Api::V1::AccountControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      firebase_uid: "uid_context",
      email: "context@example.com",
      display_name: "Context User",
      role: "viewer",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    @token = "valid_token"
    @payload = { "sub" => @user.firebase_uid }
  end

  test "should return full account context with owned_vaults array" do
    @user.create_vault!(display_name: "My Vault")

    other_owner = User.create!(email: "other@example.com", display_name: "Other")
    other_vault = other_owner.create_vault!(display_name: "Other Vault")
    @user.permissions.create!(vault: other_vault, granted_level: 3)

    FirebaseIdToken::Signature.stub :verify, @payload do
      get api_v1_account_context_path, headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success
    json = response.parsed_body
    assert_equal "success", json["status"]
    assert json["account"]["capabilities"]["can_create_vault"]

    owned = json["account"]["owned_vaults"]
    assert_equal 1, owned.size
    assert_equal "My Vault", owned.first["display_name"]

    received = json["account"]["received_vaults"]
    assert_equal 1, received.size
    assert_equal "Other Vault", received.first["display_name"]
    assert_equal 3, received.first["trust_level"]
  end

  test "vault_quota is present in capabilities" do
    FirebaseIdToken::Signature.stub :verify, @payload do
      get api_v1_account_context_path, headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success
    assert_equal 3, response.parsed_body["account"]["capabilities"]["vault_quota"]
  end
end
