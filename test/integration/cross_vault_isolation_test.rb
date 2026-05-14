require "test_helper"
require "minitest/mock"

# MT-14: Cross-vault data-leakage test sweep.
# Proves that a user active in Vault A cannot read, write, or audit Vault B.
class CrossVaultIsolationTest < ActionDispatch::IntegrationTest
  setup do
    @alice = User.create!(
      firebase_uid: "alice_uid",
      email: "alice@example.com",
      display_name: "Alice",
      role: "owner",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    @bob = User.create!(
      firebase_uid: "bob_uid",
      email: "bob@example.com",
      display_name: "Bob",
      role: "owner",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )

    @alice_vault = @alice.owned_vaults.create!(display_name: "Alice Vault")
    @bob_vault   = @bob.owned_vaults.create!(display_name: "Bob Vault")

    @alice.update!(default_vault_id: @alice_vault.id)
    @bob.update!(default_vault_id: @bob_vault.id)

    @alice_token = "alice_valid_token"
    @bob_token   = "bob_valid_token"
    @alice_payload = { "sub" => @alice.firebase_uid }
    @bob_payload   = { "sub" => @bob.firebase_uid }
  end

  # ─── Header forgery: X-BK-Active-Vault pointing at foreign vault ──────────

  test "X-BK-Active-Vault pointing at foreign vault returns 404" do
    bob_content = @bob_vault.contents.create!(title: "Bob's secret", body: "B", required_level: 0)

    FirebaseIdToken::Signature.stub :verify, @alice_payload do
      get api_v1_my_contents_path,
          headers: {
            "Authorization" => "Bearer #{@alice_token}",
            "X-BK-Active-Vault" => @bob_vault.id.to_s
          }
    end

    assert_response :not_found
    assert_equal "vault_not_found", response.parsed_body["message"]
  end

  # ─── Cross-vault content read ──────────────────────────────────────────────

  test "Alice cannot read Bob's contents via default vault resolution" do
    bob_content = @bob_vault.contents.create!(title: "Bob's content", body: "B", required_level: 0)

    FirebaseIdToken::Signature.stub :verify, @alice_payload do
      get api_v1_content_path(bob_content),
          headers: { "Authorization" => "Bearer #{@alice_token}" }
    end

    assert_response :not_found
  end

  # ─── Cross-vault audit log read ────────────────────────────────────────────

  test "Alice cannot read Bob's audit logs" do
    @bob_vault.audit_logs.create!(
      user: @bob,
      action: "view",
      occurred_at: Time.current
    )

    FirebaseIdToken::Signature.stub :verify, @alice_payload do
      get api_v1_my_audit_logs_path,
          headers: {
            "Authorization" => "Bearer #{@alice_token}",
            "X-BK-Active-Vault" => @alice_vault.id.to_s
          }
    end

    assert_response :success
    log_ids = response.parsed_body["audit_logs"].map { |l| l["vault_id"] }.uniq
    assert_not_includes log_ids, @bob_vault.id
  end

  # ─── Cross-vault analytics read ───────────────────────────────────────────

  test "Alice cannot read Bob's analytics via header forgery" do
    FirebaseIdToken::Signature.stub :verify, @alice_payload do
      get api_v1_my_analytics_funnel_path,
          headers: {
            "Authorization" => "Bearer #{@alice_token}",
            "X-BK-Active-Vault" => @bob_vault.id.to_s
          }
    end

    assert_response :not_found
    assert_equal "vault_not_found", response.parsed_body["message"]
  end

  # ─── Cross-vault content write ────────────────────────────────────────────

  test "Alice cannot create content in Bob's vault via header forgery" do
    FirebaseIdToken::Signature.stub :verify, @alice_payload do
      assert_no_difference "Content.count" do
        post api_v1_my_contents_path,
             params: { content: { title: "Injected", body: "Evil", required_level: 0 } },
             headers: {
               "Authorization" => "Bearer #{@alice_token}",
               "X-BK-Active-Vault" => @bob_vault.id.to_s
             }
      end
    end

    assert_response :not_found
  end

  # ─── Archived vault → 409, not silent skip ────────────────────────────────

  test "X-BK-Active-Vault pointing at own archived vault returns 409" do
    @alice_vault.update!(archived_at: Time.current)

    FirebaseIdToken::Signature.stub :verify, @alice_payload do
      get api_v1_my_audit_logs_path,
          headers: {
            "Authorization" => "Bearer #{@alice_token}",
            "X-BK-Active-Vault" => @alice_vault.id.to_s
          }
    end

    assert_response :conflict
    assert_equal "active_vault_required", response.parsed_body["message"]
  end

  # ─── Cross-vault permission update (BKC) ──────────────────────────────────

  test "Alice cannot update a permission in Bob's vault via BKC" do
    bob_viewer = User.create!(email: "viewer@example.com", display_name: "V", role: "viewer")
    perm = @bob_vault.permissions.create!(
      user: bob_viewer,
      granted_level: 3,
      status: "active"
    )

    patch bkc_viewer_path(perm), headers: { "X-Test-User-Id" => @alice.id }

    # Alice's current_vault is her own vault, so find(perm.id) on alice's
    # vault permissions will raise RecordNotFound.
    assert_response :not_found
  end

  # ─── Viewer with L3 in Vault A cannot see L9 content in Vault A ──────────

  test "viewer with L3 permission cannot access L9-required content in their vault" do
    carol = User.create!(
      firebase_uid: "carol_uid",
      email: "carol@example.com",
      display_name: "Carol",
      role: "viewer",
      status: "active",
      trust_level: 0
    )
    @alice_vault.permissions.create!(user: carol, granted_level: 3, status: "active")
    sensitive = @alice_vault.contents.create!(title: "Secret", body: "Top secret", required_level: 9)
    carol_payload = { "sub" => carol.firebase_uid }

    FirebaseIdToken::Signature.stub :verify, carol_payload do
      get api_v1_content_path(sensitive),
          headers: { "Authorization" => "Bearer #{@alice_token}" }
    end

    assert_response :not_found
  end
end
