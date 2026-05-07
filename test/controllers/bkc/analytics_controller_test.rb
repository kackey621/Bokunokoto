require "test_helper"

class Bkc::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      email: "aowner@example.com",
      display_name: "Analytics Owner",
      role: "owner",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    @vault = @owner.create_vault!(display_name: "Analytics Vault")
  end

  test "GET show renders dashboard" do
    get bkc_analytics_path, headers: { "X-Test-User-Id" => @owner.id }

    assert_response :success
    assert_select "h5", text: /Trust Level Funnel/
    assert_select "h5", text: /Access Link Attribution/
    assert_select "h5", text: /Accessibility Coverage/
    assert_select "h5", text: /Greeting Delivery/
  end

  test "show populates the new query results without erroring" do
    @vault.access_links.create!(slug: "abc-test-show", initial_level: 1)
    @vault.contents.create!(title: "C", body: "B", format: "markdown", required_level: 0, symbol_type: "rainbow")

    get bkc_analytics_path, headers: { "X-Test-User-Id" => @owner.id }

    assert_response :success
    assert_select "code", text: "abc-test-show"
  end

  test "GET show honors date_range param" do
    get bkc_analytics_path(date_range: "7"), headers: { "X-Test-User-Id" => @owner.id }
    assert_response :success
    assert_select "select[name=?] option[selected]", "date_range" do
      assert_select "[value=?]", "7"
    end
  end

  test "GET show without vault redirects" do
    no_vault_user = User.create!(email: "nv@x.com", display_name: "NV", role: "viewer", status: "active")

    get bkc_analytics_path, headers: { "X-Test-User-Id" => no_vault_user.id }

    assert_redirected_to bkc_dashboard_path
  end
end
