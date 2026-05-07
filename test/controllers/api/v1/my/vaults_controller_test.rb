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

  test "stores bank_account_info as JSON and returns masked + parsed view" do
    vault = @user.create_vault!(display_name: "V")

    FirebaseIdToken::Signature.stub :verify, @payload do
      patch api_v1_my_vault_path,
            params: {
              vault: {
                bank_account_info: {
                  account_number: "0123456789",
                  bank_name: "Mizuho",
                  routing_number: "001"
                }
              }
            },
            headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success

    body = response.parsed_body
    assert_equal "012-****-6789", body["vault"]["masked_account_number"]
    assert_equal "Mizuho", body["vault"]["bank_account_info"]["bank_name"]
    assert_equal "001", body["vault"]["bank_account_info"]["routing_number"]

    # Stored value is JSON, not Hash#to_s — round-trips through bank_account_data.
    parsed = JSON.parse(vault.reload.bank_account_info)
    assert_equal "0123456789", parsed["account_number"]
    assert_equal "Mizuho", parsed["bank_name"]
  end

  test "GET vault returns parsed bank_account_info hash" do
    vault = @user.create_vault!(display_name: "V")
    vault.bank_account_data = { account_number: "9876543210", bank_name: "SMBC" }
    vault.save!

    FirebaseIdToken::Signature.stub :verify, @payload do
      get api_v1_my_vault_path, headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success
    info = response.parsed_body["vault"]["bank_account_info"]
    assert_equal "SMBC", info["bank_name"]
    assert_equal "987-****-3210", response.parsed_body["vault"]["masked_account_number"]
  end
end
