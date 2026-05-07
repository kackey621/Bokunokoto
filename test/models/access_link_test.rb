require "test_helper"

class AccessLinkTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @vault = Vault.create!(user: @user, display_name: "Test Vault")
  end

  test "should create access link with valid attributes" do
    link = AccessLink.new(
      vault: @vault,
      slug: "test-link-123",
      initial_level: 3,
      welcome_message: "Welcome!",
      preset_context: { key: "value" }
    )
    assert link.save
  end

  test "slug must be unique" do
    AccessLink.create!(
      vault: @vault,
      slug: "unique-slug",
      initial_level: 0
    )
    link = AccessLink.new(
      vault: @vault,
      slug: "unique-slug",
      initial_level: 0
    )
    assert_not link.save
    assert link.errors[:slug].present?
  end

  test "slug format validation" do
    invalid_slugs = ["Test-Link", "test link", "test_link", "test@link"]
    invalid_slugs.each do |slug|
      link = AccessLink.new(vault: @vault, slug: slug, initial_level: 0)
      assert_not link.save, "Should reject slug: #{slug}"
    end

    valid_slugs = ["test-link", "test123", "test-link-123"]
    valid_slugs.each do |slug|
      link = AccessLink.new(vault: @vault, slug: slug, initial_level: 0)
      assert link.save, "Should accept slug: #{slug}"
      link.destroy
    end
  end

  test "initial_level must be between 0 and 9" do
    invalid_link = AccessLink.new(vault: @vault, slug: "test", initial_level: 10)
    assert_not invalid_link.save

    valid_link = AccessLink.new(vault: @vault, slug: "test", initial_level: 9)
    assert valid_link.save
  end

  test "expired scope returns only expired links" do
    expired = AccessLink.create!(
      vault: @vault,
      slug: "expired-link",
      initial_level: 0,
      expires_at: 1.hour.ago
    )
    active = AccessLink.create!(
      vault: @vault,
      slug: "active-link",
      initial_level: 0,
      expires_at: 1.hour.from_now
    )

    assert_includes AccessLink.expired, expired
    assert_not_includes AccessLink.expired, active
  end

  test "active scope returns non-expired links" do
    expired = AccessLink.create!(
      vault: @vault,
      slug: "expired-link",
      initial_level: 0,
      expires_at: 1.hour.ago
    )
    active = AccessLink.create!(
      vault: @vault,
      slug: "active-link",
      initial_level: 0,
      expires_at: 1.hour.from_now
    )
    no_expiry = AccessLink.create!(
      vault: @vault,
      slug: "no-expiry-link",
      initial_level: 0
    )

    assert_includes AccessLink.active, active
    assert_includes AccessLink.active, no_expiry
    assert_not_includes AccessLink.active, expired
  end

  test "available scope filters by max_uses" do
    exceeded = AccessLink.create!(
      vault: @vault,
      slug: "exceeded-uses",
      initial_level: 0,
      max_uses: 2,
      use_count: 2
    )
    available = AccessLink.create!(
      vault: @vault,
      slug: "available-uses",
      initial_level: 0,
      max_uses: 2,
      use_count: 1
    )

    assert_includes AccessLink.available, available
    assert_not_includes AccessLink.available, exceeded
  end

  test "expired? returns true when expires_at is in past" do
    expired = AccessLink.new(
      vault: @vault,
      slug: "test",
      initial_level: 0,
      expires_at: 1.hour.ago
    )
    assert expired.expired?

    active = AccessLink.new(
      vault: @vault,
      slug: "test",
      initial_level: 0,
      expires_at: 1.hour.from_now
    )
    assert_not active.expired?
  end

  test "max_uses_exceeded? returns true when use_count >= max_uses" do
    link = AccessLink.new(
      vault: @vault,
      slug: "test",
      initial_level: 0,
      max_uses: 5,
      use_count: 5
    )
    assert link.max_uses_exceeded?

    link.use_count = 4
    assert_not link.max_uses_exceeded?
  end

  test "valid_for_handshake? returns true only when not expired and uses not exceeded" do
    link = AccessLink.new(
      vault: @vault,
      slug: "test",
      initial_level: 0,
      expires_at: 1.hour.from_now,
      max_uses: 5,
      use_count: 3
    )
    assert link.valid_for_handshake?

    link.expires_at = 1.hour.ago
    assert_not link.valid_for_handshake?

    link.expires_at = 1.hour.from_now
    link.use_count = 5
    assert_not link.valid_for_handshake?
  end

  test "use! increments use_count" do
    link = AccessLink.create!(
      vault: @vault,
      slug: "test",
      initial_level: 0,
      use_count: 0
    )
    link.use!
    assert_equal 1, link.use_count
    link.use!
    assert_equal 2, link.use_count
  end
end
