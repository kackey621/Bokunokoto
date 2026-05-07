require "test_helper"

class Api::V1::HandshakeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @vault = vaults(:one)
    @access_link = AccessLink.create!(
      vault: @vault,
      slug: "test-handshake",
      initial_level: 3,
      welcome_message: "Welcome to my vault!",
      preset_context: { relationship: "friend" }
    )
  end

  test "should create permission with valid access link" do
    assert_difference "Permission.count", 1 do
      post api_v1_handshake_path, params: {
        handshake: {
          slug: @access_link.slug,
          firebase_uid: @user.firebase_uid
        }
      }
    end

    assert_response :created
    json = response.parsed_body
    assert json["permission"]
    assert json["vault"]
    assert_equal "Welcome to my vault!", json["welcome_message"]
    assert_equal 3, json["initial_level"]
  end

  test "should return error with invalid slug" do
    assert_no_difference "Permission.count" do
      post api_v1_handshake_path, params: {
        handshake: {
          slug: "nonexistent-slug",
          firebase_uid: @user.firebase_uid
        }
      }
    end

    assert_response :not_found
    json = response.parsed_body
    assert_equal "Invalid access link", json["error"]
  end

  test "should reject expired access link" do
    @access_link.update(expires_at: 1.hour.ago)

    assert_no_difference "Permission.count" do
      post api_v1_handshake_path, params: {
        handshake: {
          slug: @access_link.slug,
          firebase_uid: @user.firebase_uid
        }
      }
    end

    assert_response :forbidden
    json = response.parsed_body
    assert_equal "Access link expired or max uses exceeded", json["error"]
  end

  test "should reject access link when max uses exceeded" do
    @access_link.update(max_uses: 2, use_count: 2)

    assert_no_difference "Permission.count" do
      post api_v1_handshake_path, params: {
        handshake: {
          slug: @access_link.slug,
          firebase_uid: @user.firebase_uid
        }
      }
    end

    assert_response :forbidden
    json = response.parsed_body
    assert_equal "Access link expired or max uses exceeded", json["error"]
  end

  test "should increment use_count after handshake" do
    initial_count = @access_link.use_count
    post api_v1_handshake_path, params: {
      handshake: {
        slug: @access_link.slug,
        firebase_uid: @user.firebase_uid
      }
    }

    @access_link.reload
    assert_equal initial_count + 1, @access_link.use_count
  end

  test "should set initial_level from access link" do
    @access_link.update(initial_level: 5)
    post api_v1_handshake_path, params: {
      handshake: {
        slug: @access_link.slug,
        firebase_uid: @user.firebase_uid
      }
    }

    permission = Permission.last
    assert_equal 5, permission.granted_level
  end

  test "should associate permission with access link" do
    post api_v1_handshake_path, params: {
      handshake: {
        slug: @access_link.slug,
        firebase_uid: @user.firebase_uid
      }
    }

    permission = Permission.last
    assert_equal @access_link.id, permission.source_access_link_id
  end

  test "should update existing permission on second handshake" do
    # First handshake
    post api_v1_handshake_path, params: {
      handshake: {
        slug: @access_link.slug,
        firebase_uid: @user.firebase_uid
      }
    }
    permission1 = Permission.last
    permission_id = permission1.id

    # Second handshake with different link but same user/vault
    @access_link2 = AccessLink.create!(
      vault: @vault,
      slug: "test-handshake-2",
      initial_level: 7
    )

    post api_v1_handshake_path, params: {
      handshake: {
        slug: @access_link2.slug,
        firebase_uid: @user.firebase_uid
      }
    }

    # Permission should be updated, not created
    permission2 = Permission.find(permission_id)
    assert_equal @access_link2.id, permission2.source_access_link_id
  end

  test "should return error with nonexistent user" do
    post api_v1_handshake_path, params: {
      handshake: {
        slug: @access_link.slug,
        firebase_uid: "nonexistent-uid"
      }
    }

    assert_response :not_found
    json = response.parsed_body
    assert_equal "User not found", json["error"]
  end
end
