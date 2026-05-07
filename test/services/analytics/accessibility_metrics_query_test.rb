require "test_helper"

module Analytics
  class AccessibilityMetricsQueryTest < ActiveSupport::TestCase
    setup do
      @owner = User.create!(email: "owner@example.com", display_name: "Owner", role: "owner")
      @vault = @owner.create_vault!(display_name: "Vault")
      @viewer = User.create!(email: "v@x.com", display_name: "V", role: "viewer")
    end

    test "returns zeroed format buckets when there are no contents or views" do
      result = AccessibilityMetricsQuery.new(vault: @vault).execute

      assert_equal({ "markdown" => 0, "html" => 0, "text" => 0 }, result[:format_views])
      assert_equal 0, result[:summary][:total_views]
      assert_equal 0, result[:summary][:total_contents]
    end

    test "tallies views per content format" do
      md = @vault.contents.create!(title: "MD", body: "Hi", format: "markdown", required_level: 0)
      html = @vault.contents.create!(title: "HTML", body: "<p>Hi</p>", format: "html", required_level: 0)

      AuditLog.create!(vault: @vault, user: @viewer, content: md, action: "view", occurred_at: Time.current)
      AuditLog.create!(vault: @vault, user: @viewer, content: md, action: "view", occurred_at: Time.current)
      AuditLog.create!(vault: @vault, user: @viewer, content: html, action: "view", occurred_at: Time.current)

      result = AccessibilityMetricsQuery.new(vault: @vault).execute

      assert_equal 2, result[:format_views]["markdown"]
      assert_equal 1, result[:format_views]["html"]
      assert_equal 0, result[:format_views]["text"]
      assert_equal 3, result[:summary][:total_views]
    end

    test "reports symbol coverage" do
      @vault.contents.create!(title: "A", body: "Hi", format: "text", required_level: 0, symbol_type: "rainbow")
      @vault.contents.create!(title: "B", body: "Hi", format: "text", required_level: 0, symbol_type: "rainbow")
      @vault.contents.create!(title: "C", body: "Hi", format: "text", required_level: 0, symbol_type: "help_mark")
      @vault.contents.create!(title: "D", body: "Hi", format: "text", required_level: 0)

      result = AccessibilityMetricsQuery.new(vault: @vault).execute

      assert_equal 2, result[:symbol_coverage]["rainbow"]
      assert_equal 1, result[:symbol_coverage]["help_mark"]
      assert_equal 3, result[:summary][:contents_with_symbols]
      assert_equal 4, result[:summary][:total_contents]
    end
  end
end
