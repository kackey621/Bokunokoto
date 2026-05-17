require "test_helper"

class Bkc::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "bkc-signout@example.com",
      display_name: "BKC Signout User",
      role: "owner",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    @user.owned_vaults.create!(display_name: "Signout Vault")
  end

  test "destroy responds without ArgumentError from skip_before_action" do
    assert_nothing_raised do
      delete bkc_session_path, headers: { "X-Test-User-Id" => @user.id }
    end

    assert_response :redirect
    assert_redirected_to root_path
    assert_equal "Signed out from BKC successfully.", flash[:notice]
  end

  test "destroy succeeds even when user has no vault" do
    no_vault_user = User.create!(
      email: "novault@example.com",
      display_name: "No Vault User",
      role: "viewer",
      status: "active",
      trust_level: 0,
      can_create_vault: false
    )

    delete bkc_session_path, headers: { "X-Test-User-Id" => no_vault_user.id }

    assert_response :redirect
    assert_redirected_to root_path
  end
end
