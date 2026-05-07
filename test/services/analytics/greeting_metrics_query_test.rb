require "test_helper"

module Analytics
  class GreetingMetricsQueryTest < ActiveSupport::TestCase
    setup do
      @owner = User.create!(email: "owner@example.com", display_name: "Owner", role: "owner")
      @vault = @owner.create_vault!(display_name: "Vault")
      @recipient = User.create!(email: "r@x.com", display_name: "R", role: "viewer")
    end

    test "zeroed structure with no greetings" do
      result = GreetingMetricsQuery.new(vault: @vault).execute

      assert_equal 0, result[:total]
      assert_equal 0, result[:unlocked]
      assert_equal 0.0, result[:open_rate]
      assert_equal({ within_1m: 0, within_1h: 0, within_1d: 0, later: 0 }, result[:time_to_open_buckets])
    end

    test "computes open rate and bucket distribution" do
      sched = 5.days.ago

      g1 = create_greeting(scheduled_delivery_time: sched)
      g2 = create_greeting(scheduled_delivery_time: sched)
      g3 = create_greeting(scheduled_delivery_time: sched)
      _g4_locked = create_greeting(scheduled_delivery_time: 1.day.from_now)

      [
        [ g1, sched + 30.seconds ],   # within_1m
        [ g2, sched + 30.minutes ],   # within_1h
        [ g3, sched + 6.hours ]      # within_1d
      ].each do |g, opened_at|
        g.update_columns(unlocked_at: opened_at)
      end

      result = GreetingMetricsQuery.new(vault: @vault).execute

      assert_equal 4, result[:total]
      assert_equal 3, result[:unlocked]
      assert_equal 1, result[:locked]
      assert_in_delta 0.75, result[:open_rate], 0.001

      assert_equal 1, result[:time_to_open_buckets][:within_1m]
      assert_equal 1, result[:time_to_open_buckets][:within_1h]
      assert_equal 1, result[:time_to_open_buckets][:within_1d]
      assert_equal 0, result[:time_to_open_buckets][:later]
    end

    test "scopes to vault" do
      other = User.create!(email: "other@x.com", display_name: "Other", role: "owner").create_vault!(display_name: "Other")
      Greeting.create!(vault: other, recipient_user: @recipient, content: "x", scheduled_delivery_time: 1.day.from_now)

      result = GreetingMetricsQuery.new(vault: @vault).execute
      assert_equal 0, result[:total]
    end

    private

    def create_greeting(scheduled_delivery_time:)
      g = Greeting.new(
        vault: @vault,
        recipient_user: @recipient,
        content: "Happy birthday",
        scheduled_delivery_time: 1.day.from_now,
        unlock_animation_type: "fade"
      )
      g.save!(validate: false)
      g.update_columns(scheduled_delivery_time: scheduled_delivery_time)
      g.reload
    end
  end
end
