require "test_helper"
require "minitest/mock"

class Api::V1::My::VaultsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      firebase_uid: "uid_123",
      email: "test@example.com",
      display_name: "Test User",
      role: "viewer",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    @token = "valid_token"
    @payload = { "sub" => @user.firebase_uid }
  end

  test "should get own vault info" do
    @user.create_vault!(display_name: "My Vault", bio: "My bio")

    FirebaseIdToken::Signature.stub :verify, @payload do
      get api_v1_my_vault_path, headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success
    json = response.parsed_body
    assert_equal "My Vault", json["vault"]["display_name"]
  end

  test "should return error if no vault exists" do
    FirebaseIdToken::Signature.stub :verify, @payload do
      get api_v1_my_vault_path, headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :not_found
  end

  test "should create vault" do
    FirebaseIdToken::Signature.stub :verify, @payload do
      assert_difference "Vault.count", 1 do
        post api_v1_my_vault_path, 
             params: { vault: { display_name: "New Vault", bio: "New bio" } },
             headers: { "Authorization" => "Bearer #{@token}" }
      end
    end

    assert_response :created
    assert_equal "New Vault", response.parsed_body["vault"]["display_name"]
    assert_equal "New Vault", @user.reload.vault.display_name
  end

  test "should not create vault if already exists" do
    @user.create_vault!(display_name: "Existing Vault")

    FirebaseIdToken::Signature.stub :verify, @payload do
      assert_no_difference "Vault.count" do
        post api_v1_my_vault_path, 
             params: { vault: { display_name: "Another Vault" } },
             headers: { "Authorization" => "Bearer #{@token}" }
      end
    end

    assert_response :unprocessable_entity
    assert_match /already have an active vault/, response.parsed_body["message"]
  end

  test "should not create vault if capability disabled" do
    @user.update!(can_create_vault: false)

    FirebaseIdToken::Signature.stub :verify, @payload do
      assert_no_difference "Vault.count" do
        post api_v1_my_vault_path, 
             params: { vault: { display_name: "Forbidden Vault" } },
             headers: { "Authorization" => "Bearer #{@token}" }
      end
    end

    assert_response :forbidden
  end

  test "should update vault" do
    vault = @user.create_vault!(display_name: "Old Name")

    FirebaseIdToken::Signature.stub :verify, @payload do
      patch api_v1_my_vault_path, 
            params: { vault: { display_name: "New Name" } },
            headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success
    assert_equal "New Name", vault.reload.display_name
  end
end
