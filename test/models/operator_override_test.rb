require "test_helper"

class OperatorOverrideTest < ActiveSupport::TestCase
  setup do
    @operator = User.create!(
      email: "model-op@example.com",
      display_name: "Model Operator",
      role: "operator",
      status: "active",
      trust_level: 9,
      can_create_vault: true
    )
    @owner = User.create!(
      email: "model-owner@example.com",
      display_name: "Model Owner",
      role: "owner",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    @vault = @owner.owned_vaults.create!(display_name: "Model Vault")
  end

  test "MAX_DURATION constant is defined" do
    assert_equal 8.hours, OperatorOverride::MAX_DURATION
  end

  test "open! clamps duration to MAX_DURATION when exceeded" do
    requested_duration = 24.hours
    freeze = Time.current

    travel_to(freeze) do
      override = OperatorOverride.open!(
        operator: @operator,
        vault: @vault,
        reason: "Long duration attempt",
        duration: requested_duration
      )

      expected_expiry = freeze + OperatorOverride::MAX_DURATION
      assert_in_delta expected_expiry.to_i, override.expires_at.to_i, 1
    end
  end

  test "open! honors duration shorter than MAX_DURATION" do
    requested_duration = 15.minutes
    freeze = Time.current

    travel_to(freeze) do
      override = OperatorOverride.open!(
        operator: @operator,
        vault: @vault,
        reason: "Short duration",
        duration: requested_duration
      )

      expected_expiry = freeze + requested_duration
      assert_in_delta expected_expiry.to_i, override.expires_at.to_i, 1
    end
  end

  test "open! uses DEFAULT_DURATION when no duration provided" do
    freeze = Time.current

    travel_to(freeze) do
      override = OperatorOverride.open!(
        operator: @operator,
        vault: @vault,
        reason: "Default duration"
      )

      expected_expiry = freeze + OperatorOverride::DEFAULT_DURATION
      assert_in_delta expected_expiry.to_i, override.expires_at.to_i, 1
    end
  end
end
