require "test_helper"

class Console::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "viewer@example.test",
      display_name: "Viewer",
      role: "viewer",
      status: "active",
      trust_level: 1
    )
    @admin_headers = as_platform_admin
  end

  test "lists users" do
    get console_users_path, headers: @admin_headers

    assert_response :success
    assert_select "h1", "User Management"
    assert_select "td", "viewer@example.test"
  end

  test "creates user" do
    assert_difference "User.count" do
      post console_users_path, params: {
        user: {
          email: "admin@example.test",
          display_name: "Admin",
          role: "admin",
          status: "active",
          trust_level: 9
        }
      }, headers: @admin_headers
    end

    assert_redirected_to console_user_path(User.order(:created_at).last)
  end

  test "archives user instead of deleting" do
    delete console_user_path(@user), headers: @admin_headers

    assert_redirected_to console_users_path
    assert_equal "archived", @user.reload.status
  end

  test "non-admin user is forbidden" do
    viewer = User.create!(
      email: "non-admin@example.test",
      display_name: "Non Admin",
      role: "viewer",
      status: "active",
      trust_level: 0
    )

    get console_users_path, headers: { "X-Test-User-Id" => viewer.id.to_s }

    assert_response :forbidden
  end

  test "unauthenticated request is forbidden" do
    get console_users_path

    assert_response :forbidden
  end
end
