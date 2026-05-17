require "test_helper"
require "minitest/mock"

class Api::V1::My::VaultsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      firebase_uid: "uid_123",
      email: "test@example.com",
      display_name: "Test User",
      role: "owner",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    @token = "valid_token"
    @payload = { "sub" => @user.firebase_uid }
  end

  # ─── Index ────────────────────────────────────────────────────────────────

  test "GET /my/vaults returns list of active vaults" do
    v1 = @user.owned_vaults.create!(display_name: "Vault 1")
    v2 = @user.owned_vaults.create!(display_name: "Vault 2", archived_at: Time.current)

    FirebaseIdToken::Signature.stub :verify, @payload do
      get api_v1_my_vaults_path, headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success
    json = response.parsed_body
    ids = json["vaults"].map { |v| v["id"] }
    assert_includes ids, v1.id
    assert_not_includes ids, v2.id
  end

  # ─── Show ─────────────────────────────────────────────────────────────────

  test "GET /my/vaults/:id returns vault" do
    vault = @user.owned_vaults.create!(display_name: "My Vault", bio: "My bio")

    FirebaseIdToken::Signature.stub :verify, @payload do
      get api_v1_my_vault_path(vault), headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success
    assert_equal "My Vault", response.parsed_body["vault"]["display_name"]
  end

  test "GET /my/vaults/:id returns 404 for vault not owned by user" do
    other_owner = User.create!(email: "other@example.com", display_name: "Other", role: "owner")
    other_vault = other_owner.owned_vaults.create!(display_name: "Other Vault")

    FirebaseIdToken::Signature.stub :verify, @payload do
      get api_v1_my_vault_path(other_vault), headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :not_found
  end

  # ─── Create ───────────────────────────────────────────────────────────────

  test "POST /my/vaults creates a vault" do
    FirebaseIdToken::Signature.stub :verify, @payload do
      assert_difference "Vault.count", 1 do
        post api_v1_my_vaults_path,
             params: { vault: { display_name: "New Vault", bio: "New bio" } },
             headers: { "Authorization" => "Bearer #{@token}" }
      end
    end

    assert_response :created
    assert_equal "New Vault", response.parsed_body["vault"]["display_name"]
    assert_equal "New Vault", @user.reload.owned_vaults.last.display_name
  end

  test "POST /my/vaults returns 422 when quota exceeded" do
    @user.update!(vault_quota: 1)
    @user.owned_vaults.create!(display_name: "Existing Vault")

    FirebaseIdToken::Signature.stub :verify, @payload do
      assert_no_difference "Vault.count" do
        post api_v1_my_vaults_path,
             params: { vault: { display_name: "Another Vault" } },
             headers: { "Authorization" => "Bearer #{@token}" }
      end
    end

    assert_response :unprocessable_entity
    assert_equal "vault_quota_exceeded", response.parsed_body["message"]
  end

  test "POST /my/vaults returns 403 when capability disabled" do
    @user.update!(can_create_vault: false)

    FirebaseIdToken::Signature.stub :verify, @payload do
      assert_no_difference "Vault.count" do
        post api_v1_my_vaults_path,
             params: { vault: { display_name: "Forbidden Vault" } },
             headers: { "Authorization" => "Bearer #{@token}" }
      end
    end

    assert_response :forbidden
  end

  test "POST /my/vaults sets default_vault_id on first vault" do
    FirebaseIdToken::Signature.stub :verify, @payload do
      post api_v1_my_vaults_path,
           params: { vault: { display_name: "First Vault" } },
           headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :created
    vault = Vault.last
    assert_equal vault.id, @user.reload.default_vault_id
  end

  # ─── Update ───────────────────────────────────────────────────────────────

  test "PATCH /my/vaults/:id updates vault" do
    vault = @user.owned_vaults.create!(display_name: "Old Name")

    FirebaseIdToken::Signature.stub :verify, @payload do
      patch api_v1_my_vault_path(vault),
            params: { vault: { display_name: "New Name" } },
            headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success
    assert_equal "New Name", vault.reload.display_name
  end

  # ─── Archive / Restore ────────────────────────────────────────────────────

  test "POST /my/vaults/:id/archive archives a vault" do
    vault = @user.owned_vaults.create!(display_name: "Active Vault")

    FirebaseIdToken::Signature.stub :verify, @payload do
      post archive_api_v1_my_vault_path(vault), headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success
    assert_not_nil vault.reload.archived_at
  end

  test "POST /my/vaults/:id/restore restores a vault" do
    vault = @user.owned_vaults.create!(display_name: "Archived", archived_at: Time.current)

    FirebaseIdToken::Signature.stub :verify, @payload do
      post restore_api_v1_my_vault_path(vault), headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success
    assert_nil vault.reload.archived_at
  end

  # ─── Bank account ─────────────────────────────────────────────────────────

  # CRITICAL-001: the JSON response now exposes only the masked account
  # digest. The plaintext stays encrypted in the DB and is no longer
  # serialised on read/write.
  test "stores bank_account_info as JSON but only returns masked view" do
    vault = @user.owned_vaults.create!(display_name: "V")
    @user.update!(default_vault_id: vault.id)

    FirebaseIdToken::Signature.stub :verify, @payload do
      patch api_v1_my_vault_path(vault),
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
    assert_nil body["vault"]["bank_account_info"],
      "plaintext bank_account_info must not appear in API response (CRITICAL-001)"

    parsed = JSON.parse(vault.reload.bank_account_info)
    assert_equal "0123456789", parsed["account_number"]
    assert_equal "Mizuho", parsed["bank_name"]
  end

  test "GET /my/vaults/:id returns masked digest, never plaintext" do
    vault = @user.owned_vaults.create!(display_name: "V")
    vault.bank_account_data = { account_number: "9876543210", bank_name: "SMBC" }
    vault.save!

    FirebaseIdToken::Signature.stub :verify, @payload do
      get api_v1_my_vault_path(vault), headers: { "Authorization" => "Bearer #{@token}" }
    end

    assert_response :success
    body = response.parsed_body
    assert_equal "987-****-3210", body["vault"]["masked_account_number"]
    assert_nil body["vault"]["bank_account_info"],
      "plaintext bank_account_info must not appear in API response (CRITICAL-001)"
  end
end
