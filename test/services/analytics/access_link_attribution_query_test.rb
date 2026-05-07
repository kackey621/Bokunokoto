require "test_helper"

module Analytics
  class AccessLinkAttributionQueryTest < ActiveSupport::TestCase
    setup do
      @owner = User.create!(email: "owner@example.com", display_name: "Owner", role: "owner")
      @vault = @owner.create_vault!(display_name: "Vault")
      @link_a = @vault.access_links.create!(slug: "abc-link-a", initial_level: 2, preset_context: "Friend")
      @link_b = @vault.access_links.create!(slug: "abc-link-b", initial_level: 0, preset_context: "Casual")
    end

    test "returns one attribution row per access link with zero counts when no permissions" do
      result = AccessLinkAttributionQuery.new(vault: @vault).execute

      assert_equal 2, result[:attributions].length
      assert result[:attributions].all? { |a| a[:clicks] == 0 }
      assert_equal 0, result[:summary][:total_conversions]
    end

    test "counts permissions sourced from each link" do
      viewer1 = User.create!(email: "v1@x.com", display_name: "V1", role: "viewer")
      viewer2 = User.create!(email: "v2@x.com", display_name: "V2", role: "viewer")
      viewer3 = User.create!(email: "v3@x.com", display_name: "V3", role: "viewer")

      Permission.create!(vault: @vault, user: viewer1, granted_level: 2, source_access_link: @link_a)
      Permission.create!(vault: @vault, user: viewer2, granted_level: 1, source_access_link: @link_a)
      Permission.create!(vault: @vault, user: viewer3, granted_level: 0, source_access_link: @link_b)

      result = AccessLinkAttributionQuery.new(vault: @vault).execute

      a_row = result[:attributions].find { |r| r[:link_id] == @link_a.id }
      b_row = result[:attributions].find { |r| r[:link_id] == @link_b.id }

      assert_equal 2, a_row[:clicks]
      assert_equal 2, a_row[:l1_conversions]
      assert_equal 1, a_row[:l2_conversions]

      assert_equal 1, b_row[:clicks]
      assert_equal 0, b_row[:l1_conversions]
      assert_equal 0, b_row[:l2_conversions]

      assert_equal 3, result[:summary][:total_conversions]
      assert_equal 2, result[:summary][:total_l1_conversions]
      assert_equal 1, result[:summary][:total_l2_conversions]
    end

    test "respects date_range" do
      viewer = User.create!(email: "v@x.com", display_name: "V", role: "viewer")
      Permission.create!(vault: @vault, user: viewer, granted_level: 2, source_access_link: @link_a, created_at: 60.days.ago)

      result = AccessLinkAttributionQuery.new(vault: @vault, date_range: 7.days.ago..Time.current).execute

      a_row = result[:attributions].find { |r| r[:link_id] == @link_a.id }
      assert_equal 0, a_row[:clicks], "permission outside the date range should not count"
    end
  end
end
