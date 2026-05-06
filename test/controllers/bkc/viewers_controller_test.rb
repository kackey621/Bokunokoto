require "test_helper"

class Bkc::ViewersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      email: "owner@example.com",
      display_name: "Owner",
      role: "owner",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    @vault = @owner.create_vault!(display_name: "Owner Vault")

    @viewer = User.create!(
      email: "viewer@example.com",
      display_name: "Viewer",
      role: "viewer"
    )
    @permission = @vault.permissions.create!(user: @viewer, granted_level: 1)
  end

  test "should get index" do
    get bkc_viewers_path, headers: { "X-Test-User-Id" => @owner.id }
    assert_response :success
    assert_select "td", "Viewer"
  end

  test "should show viewer details" do
    get bkc_viewer_path(@permission), headers: { "X-Test-User-Id" => @owner.id }
    assert_response :success
    assert_select "h4", "Viewer"
  end

  test "should update trust level" do
    patch bkc_viewer_path(@permission),
          params: { permission: { granted_level: 5, status: "suspended" } },
          headers: { "X-Test-User-Id" => @owner.id }

    assert_redirected_to bkc_viewer_path(@permission)
    @permission.reload
    assert_equal 5, @permission.granted_level
    assert_equal "suspended", @permission.status
  end

  test "should not access other vault's viewers" do
    other_owner = User.create!(email: "other@example.com", display_name: "Other", role: "owner")
    other_vault = other_owner.create_vault!(display_name: "Other Vault")
    other_permission = other_vault.permissions.create!(user: @viewer, granted_level: 1)

    get bkc_viewer_path(other_permission), headers: { "X-Test-User-Id" => @owner.id }
    assert_response :not_found
  end
end
