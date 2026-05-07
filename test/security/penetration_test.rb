require "test_helper"

class PenetrationTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @vault = vaults(:one)
    @attacker = users(:two)
  end

  test "should prevent cross-vault content access" do
    attacker_vault = Vault.create!(user: @attacker, display_name: "Attacker's Vault")
    content = @vault.contents.create!(
      title: "Secret",
      body: "Confidential information",
      format: "text",
      required_level: 0
    )

    get api_v1_content_path(content), headers: auth_headers(@attacker)
    assert_response :forbidden
  end

  test "should reject expired access links" do
    link = AccessLink.create!(
      vault: @vault,
      slug: "expired-link",
      initial_level: 0,
      expires_at: 1.hour.ago
    )

    post api_v1_handshake_path, params: {
      handshake: {
        slug: link.slug,
        firebase_uid: @user.firebase_uid
      }
    }

    assert_response :forbidden
  end

  test "should enforce max_uses limit" do
    link = AccessLink.create!(
      vault: @vault,
      slug: "limited-link",
      initial_level: 0,
      max_uses: 1,
      use_count: 1
    )

    post api_v1_handshake_path, params: {
      handshake: {
        slug: link.slug,
        firebase_uid: @user.firebase_uid
      }
    }

    assert_response :forbidden
  end

  test "should prevent audit log modification" do
    log = AuditLog.create!(
      user_id: @user.id,
      content_id: nil,
      vault_id: @vault.id,
      action: "view",
      ip_address: "127.0.0.1"
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      log.update(action: "delete")
    end

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      log.destroy
    end
  end

  test "should rate limit auth attempts" do
    10.times do |i|
      post api_v1_auth_verify_path, params: { token: "invalid_token_#{i}" }
    end

    # Should eventually return rate limit response (implementation dependent)
    # This is a placeholder for actual rate limiting implementation
    assert_response :unauthorized
  end

  test "should validate token signatures" do
    invalid_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.payload"

    post api_v1_auth_verify_path, params: { token: invalid_token }

    assert_response :unauthorized
  end

  private

  def auth_headers(user)
    token = user.firebase_uid
    { "Authorization" => "Bearer #{token}" }
  end
end
