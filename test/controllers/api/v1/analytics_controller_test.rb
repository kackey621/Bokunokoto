require "test_helper"
require "minitest/mock"

class Api::V1::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      firebase_uid: "analytics_owner_uid",
      email: "owner@example.com",
      display_name: "Owner",
      role: "owner",
      can_create_vault: true
    )
    @vault = @owner.create_vault!(display_name: "Owner Vault")

    @no_vault_user = User.create!(
      firebase_uid: "analytics_novault_uid",
      email: "no_vault@example.com",
      display_name: "No Vault",
      role: "viewer"
    )
  end

  def auth_headers
    { "Authorization" => "Bearer fake_token" }
  end

  test "GET /my/analytics/attribution returns attribution rows" do
    @vault.access_links.create!(slug: "abc-attr-test", initial_level: 1)

    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      get "/api/v1/my/analytics/attribution", headers: auth_headers
    end

    assert_response :success
    body = response.parsed_body
    assert body.key?("attributions")
    assert body.key?("summary")
  end

  test "GET /my/analytics/attribution returns 404 when no vault" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @no_vault_user.firebase_uid } do
      get "/api/v1/my/analytics/attribution", headers: auth_headers
    end

    assert_response :not_found
  end

  test "GET /my/analytics/accessibility returns format/symbol breakdown" do
    @vault.contents.create!(title: "C", body: "B", format: "markdown", required_level: 0, symbol_type: "rainbow")

    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      get "/api/v1/my/analytics/accessibility", headers: auth_headers
    end

    assert_response :success
    body = response.parsed_body
    assert body.key?("format_views")
    assert body.key?("symbol_coverage")
    assert_equal 1, body.dig("summary", "contents_with_symbols")
  end

  test "GET /my/analytics/greetings returns delivery metrics" do
    FirebaseIdToken::Signature.stub :verify, { "sub" => @owner.firebase_uid } do
      get "/api/v1/my/analytics/greetings", headers: auth_headers
    end

    assert_response :success
    body = response.parsed_body
    assert_equal 0, body["total"]
    assert body.key?("time_to_open_buckets")
  end

  test "all three endpoints require authentication" do
    %w[attribution accessibility greetings].each do |endpoint|
      FirebaseIdToken::Signature.stub :verify, nil do
        get "/api/v1/my/analytics/#{endpoint}", headers: { "Authorization" => "Bearer bad" }
      end
      assert_response :unauthorized, "endpoint #{endpoint} should require auth"
    end
  end
end
