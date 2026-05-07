require "test_helper"
require "minitest/mock"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  test "should create user with valid token" do
    token = "valid_token"
    payload = {
      "sub" => "firebase_uid_123",
      "email" => "test@example.com",
      "name" => "Test User"
    }

    FirebaseIdToken::Signature.stub :verify, payload do
      assert_difference "User.count", 1 do
        post api_v1_auth_verify_path, params: { token: token }
      end
    end

    assert_response :success
    json = response.parsed_body
    assert_equal "success", json["status"]
    assert_equal "firebase_uid_123", json["user"]["firebase_uid"]
    assert_equal "test@example.com", json["user"]["email"]
    assert_equal "Test User", json["user"]["display_name"]
    assert_equal "viewer", json["user"]["role"]
    assert_equal 0, json["user"]["trust_level"]
    assert json["user"]["capabilities"]["can_create_vault"]
    assert_not json["user"]["capabilities"]["bkc_access"]
  end

  test "should return error with invalid token" do
    token = "invalid_token"

    FirebaseIdToken::Signature.stub :verify, nil do
      assert_no_difference "User.count" do
        post api_v1_auth_verify_path, params: { token: token }
      end
    end

    assert_response :unauthorized
    json = response.parsed_body
    assert_equal "error", json["status"]
    assert_equal "Invalid Firebase ID Token", json["message"]
  end

  test "should return 401 when token is missing or blank" do
    post api_v1_auth_verify_path, params: {}
    assert_response :unauthorized
    assert_equal "Invalid Firebase ID Token", response.parsed_body["message"]

    post api_v1_auth_verify_path, params: { token: "" }
    assert_response :unauthorized
  end

  test "should return 401 when Firebase certs are not loaded (NoCertificatesError)" do
    raise_no_certs = ->(_) { raise FirebaseIdToken::Exceptions::NoCertificatesError, "no certs" }
    FirebaseIdToken::Signature.stub :verify, raise_no_certs do
      post api_v1_auth_verify_path, params: { token: "any_token" }
    end
    assert_response :unauthorized
    assert_equal "Invalid Firebase ID Token", response.parsed_body["message"]
  end
end
