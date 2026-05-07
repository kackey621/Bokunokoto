require "test_helper"

class PenetrationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      firebase_uid: "user_uid",
      email: "user@example.com",
      display_name: "User",
      role: "owner"
    )
    @vault = @user.create_vault!(display_name: "User Vault")

    @attacker = User.create!(
      firebase_uid: "attacker_uid",
      email: "attacker@example.com",
      display_name: "Attacker",
      role: "viewer"
    )

    Rack::Attack.cache.store.clear
  end

  test "cross-vault content access returns 404 to avoid leaking existence" do
    content = @vault.contents.create!(
      title: "Secret",
      body: "Confidential",
      format: "text",
      required_level: 0
    )

    FirebaseIdToken::Signature.stub :verify, { "sub" => @attacker.firebase_uid } do
      get api_v1_content_path(content), headers: auth_headers
    end

    assert_response :not_found
  end

  test "expired access link rejected with code expired" do
    link = AccessLink.create!(
      vault: @vault,
      slug: "expired-#{SecureRandom.hex(4)}",
      initial_level: 0,
      expires_at: 1.hour.ago
    )

    FirebaseIdToken::Signature.stub :verify, { "sub" => @attacker.firebase_uid } do
      post api_v1_handshake_path, params: { slug: link.slug }, headers: auth_headers
    end

    assert_response :unprocessable_entity
    assert_equal "expired", response.parsed_body["code"]
  end

  test "exhausted access link rejected with code exhausted" do
    link = AccessLink.create!(
      vault: @vault,
      slug: "limited-#{SecureRandom.hex(4)}",
      initial_level: 0,
      max_uses: 1,
      use_count: 1
    )

    FirebaseIdToken::Signature.stub :verify, { "sub" => @attacker.firebase_uid } do
      post api_v1_handshake_path, params: { slug: link.slug }, headers: auth_headers
    end

    assert_response :unprocessable_entity
    assert_equal "exhausted", response.parsed_body["code"]
  end

  test "OTP first-user lock rejects second user" do
    link = AccessLink.create!(
      vault: @vault,
      slug: "otp-#{SecureRandom.hex(4)}",
      initial_level: 0
    )
    link.claim!(@user)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @attacker.firebase_uid } do
      post api_v1_handshake_path, params: { slug: link.slug }, headers: auth_headers
    end

    assert_response :forbidden
    assert_equal "link_already_bound", response.parsed_body["code"]
  end

  test "audit log is immutable" do
    log = AuditLog.create!(
      user: @user,
      vault: @vault,
      action: "view",
      ip_address: "127.0.0.1",
      occurred_at: Time.current
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) { log.update(action: "delete") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { log.destroy }
  end

  test "rate limit triggers 429 after 5 auth verifications per IP" do
    # First 5 succeed (or fail with normal codes), 6th is rate-limited.
    FirebaseIdToken::Signature.stub :verify, nil do
      5.times do
        post api_v1_auth_verify_path, params: { token: "x" }
        refute_equal 429, response.status, "Was rate-limited too early at attempt #{response.status}"
      end

      post api_v1_auth_verify_path, params: { token: "x" }
      assert_response :too_many_requests
      assert_equal "rate_limited", response.parsed_body["code"]
      assert response.headers["Retry-After"].present?, "Retry-After header should be set"
    end
  end

  test "rate limit triggers 429 after 10 handshake attempts per IP" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @attacker.firebase_uid } do
      10.times do
        post api_v1_handshake_path, params: { slug: "anything" }, headers: auth_headers
        refute_equal 429, response.status
      end

      post api_v1_handshake_path, params: { slug: "anything" }, headers: auth_headers
      assert_response :too_many_requests
    end
  end

  test "URL/slug enumeration returns indistinguishable 404s for unknown slugs" do
    # All non-existent slugs should produce the same status + body shape so
    # an attacker cannot discriminate "valid but bound" from "doesn't exist".
    statuses = []
    bodies = []

    FirebaseIdToken::Signature.stub :verify, { "sub" => @attacker.firebase_uid } do
      [ "guess-aaaa", "guess-bbbb", "guess-cccc" ].each do |slug|
        post api_v1_handshake_path, params: { slug: slug }, headers: auth_headers
        statuses << response.status
        bodies << response.parsed_body
      end
    end

    assert_equal [ 404, 404, 404 ], statuses
    assert_equal 1, bodies.map { |b| b["code"] }.uniq.size, "404 response code should be uniform"
  end

  test "token signature validation rejects malformed JWT" do
    # No stub — let FirebaseIdToken::Signature actually try to verify.
    invalid_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.payload"

    FirebaseIdToken::Signature.stub :verify, nil do
      post api_v1_auth_verify_path, params: { token: invalid_token }
    end

    assert_response :unauthorized
  end

  test "stale or replayed token where verify returns nil is rejected" do
    # Simulates a token that has expired/been revoked: FirebaseIdToken::Signature
    # returns nil. Because BaseController re-runs `verify` on every request,
    # there's no server-side session to replay against.
    FirebaseIdToken::Signature.stub :verify, nil do
      get api_v1_my_audit_logs_path, headers: { "Authorization" => "Bearer stale_token" }
    end

    assert_response :unauthorized
  end

  test "token verifying to nonexistent firebase_uid is rejected" do
    # Simulates a forged token whose signature happens to verify but whose
    # `sub` does not correspond to any real User row.
    FirebaseIdToken::Signature.stub :verify, { "sub" => "ghost_uid" } do
      get api_v1_my_audit_logs_path, headers: auth_headers
    end

    assert_response :unauthorized
  end

  private

  def auth_headers
    { "Authorization" => "Bearer fake_token" }
  end
end
