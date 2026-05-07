require "test_helper"

class AccessLinkTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "owner@example.com", display_name: "Owner", role: "owner")
    @vault = @owner.create_vault!(display_name: "Vault")
    @viewer = User.create!(email: "viewer@example.com", display_name: "Viewer", role: "viewer")
    @other_viewer = User.create!(email: "other@example.com", display_name: "Other", role: "viewer")
  end

  test "auto-generates slug on create" do
    link = AccessLink.create!(vault: @vault, initial_level: 1)
    assert_not_nil link.slug
    assert_match(/\A[A-Za-z0-9_-]{16}\z/, link.slug)
  end

  test "slug is unique" do
    AccessLink.create!(vault: @vault, slug: "fixed-slug", initial_level: 1)
    duplicate = AccessLink.new(vault: @vault, slug: "fixed-slug", initial_level: 1)
    assert_not duplicate.valid?
  end

  test "expired? returns true past expires_at" do
    link = AccessLink.create!(vault: @vault, initial_level: 1, expires_at: 1.hour.ago)
    assert link.expired?
  end

  test "expired? false if no expiry" do
    link = AccessLink.create!(vault: @vault, initial_level: 1)
    assert_not link.expired?
  end

  test "exhausted? returns true at max_uses" do
    link = AccessLink.create!(vault: @vault, initial_level: 1, max_uses: 2, use_count: 2)
    assert link.exhausted?
  end

  test "exhausted? false if no max" do
    link = AccessLink.create!(vault: @vault, initial_level: 1, use_count: 100)
    assert_not link.exhausted?
  end

  test "bound_to_other? true if bound to a different user" do
    link = AccessLink.create!(vault: @vault, initial_level: 1, bound_user: @viewer)
    assert link.bound_to_other?(@other_viewer)
    assert_not link.bound_to_other?(@viewer)
  end

  test "claim! binds first user and increments use_count" do
    link = AccessLink.create!(vault: @vault, initial_level: 3)

    assert link.claim!(@viewer)
    assert_equal @viewer.id, link.bound_user_id
    assert_equal 1, link.use_count
  end

  test "claim! rejects bound-to-other" do
    link = AccessLink.create!(vault: @vault, initial_level: 3, bound_user: @viewer)

    assert_not link.claim!(@other_viewer)
    assert_equal 0, link.use_count
  end

  test "claim! rejects expired" do
    link = AccessLink.create!(vault: @vault, initial_level: 3, expires_at: 1.hour.ago)
    assert_not link.claim!(@viewer)
  end

  test "claim! rejects exhausted" do
    link = AccessLink.create!(vault: @vault, initial_level: 3, max_uses: 1, use_count: 1)
    assert_not link.claim!(@viewer)
  end

  test "claim! by same bound user increments and remains valid" do
    link = AccessLink.create!(vault: @vault, initial_level: 3, max_uses: 5)

    assert link.claim!(@viewer)
    assert link.claim!(@viewer)
    assert_equal 2, link.use_count
  end
end
