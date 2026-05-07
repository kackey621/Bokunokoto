require "test_helper"

class ContentTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "owner@example.com", display_name: "Owner", role: "owner")
    @vault = @owner.create_vault!(display_name: "My Vault")
    @viewer = User.create!(email: "viewer@example.com", display_name: "Viewer", role: "viewer")

    @c0 = @vault.contents.create!(title: "L0 Content", body: "L0", required_level: 0)
    @c3 = @vault.contents.create!(title: "L3 Content", body: "L3", required_level: 3)
    @c5 = @vault.contents.create!(title: "L5 Content", body: "L5", required_level: 5)
  end

  test "owner sees all content" do
    accessible = Content.accessible_for(@owner, @vault)
    assert_includes accessible, @c0
    assert_includes accessible, @c3
    assert_includes accessible, @c5
  end

  test "viewer sees content based on trust level" do
    @viewer.permissions.create!(vault: @vault, granted_level: 3)

    accessible = Content.accessible_for(@viewer, @vault)
    assert_includes accessible, @c0
    assert_includes accessible, @c3
    assert_not_includes accessible, @c5
  end

  test "viewer sees nothing without permission" do
    accessible = Content.accessible_for(@viewer, @vault)
    assert_empty accessible
  end

  test "web platform caps trust level at L4" do
    @viewer.permissions.create!(vault: @vault, granted_level: 7)

    # App context sees L5
    assert_includes Content.accessible_for(@viewer, @vault), @c5

    # Web context does not see L5
    assert_not_includes Content.accessible_for(@viewer, @vault, platform: "web"), @c5
  end

  test "viewer sees whitelisted content regardless of level" do
    @viewer.permissions.create!(vault: @vault, granted_level: 0)
    @c5.update!(permitted_user_ids: [ @viewer.id ])

    accessible = Content.accessible_for(@viewer, @vault)
    assert_includes accessible, @c5
  end

  test "viewer not in whitelist still gated by trust level" do
    other_viewer = User.create!(email: "other@example.com", display_name: "Other", role: "viewer")
    @viewer.permissions.create!(vault: @vault, granted_level: 0)
    @c5.update!(permitted_user_ids: [ other_viewer.id ])

    accessible = Content.accessible_for(@viewer, @vault)
    assert_not_includes accessible, @c5
  end

  test "suspended viewer sees nothing" do
    @viewer.permissions.create!(vault: @vault, granted_level: 5, status: "suspended")

    accessible = Content.accessible_for(@viewer, @vault)
    assert_empty accessible
  end

  test "pending viewer sees nothing" do
    @viewer.permissions.create!(vault: @vault, granted_level: 5, status: "pending")

    accessible = Content.accessible_for(@viewer, @vault)
    assert_empty accessible
  end
end
