require "test_helper"

class Console::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "renders the system console" do
    get console_path

    assert_response :success
    assert_select "h1", "System Console"
    assert_select "a", "Users"
  end
end
