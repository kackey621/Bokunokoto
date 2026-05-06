require "test_helper"

class Console::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "renders the system console for platform admin" do
    get console_path, headers: as_platform_admin

    assert_response :success
    assert_select "h1", "System Console"
    assert_select "a", "Users"
  end

  test "blocks non-admin users" do
    get console_path

    assert_response :forbidden
  end
end
