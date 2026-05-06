require "test_helper"

class Bkc::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "bkc@example.com",
      display_name: "BKC User",
      role: "viewer",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    # Mocking the session login
    # In a real app we'd use a login helper
  end

  test "should redirect to root if not logged in" do
    get bkc_dashboard_path
    assert_redirected_to root_path
    assert_equal "Please log in to access BKC.", flash[:alert]
  end

  test "should show onboarding if no vault exists but can create one" do
    get bkc_dashboard_path, headers: { "X-Test-User-Id" => @user.id }
    assert_response :success
    assert_select "h5", "Create Your Vault"
  end

  test "should show dashboard if vault exists" do
    @user.create_vault!(display_name: "Test Vault")
    get bkc_dashboard_path, headers: { "X-Test-User-Id" => @user.id }
    assert_response :success
    assert_select "dt", "Display Name"
    assert_select "dd", "Test Vault"
  end

  test "should redirect if cannot create vault and no vault exists" do
    @user.update!(can_create_vault: false)
    get bkc_dashboard_path, headers: { "X-Test-User-Id" => @user.id }
    assert_redirected_to root_path
    assert_equal "You do not have a vault and cannot create one.", flash[:alert]
  end
end
