module Analytics
  # Greeting card delivery metrics: how many were scheduled, how many opened,
  # and how long recipients took to open. Time-to-open is bucketed for the
  # dashboard; the raw mean (in seconds) is also returned so the controller
  # or a future query can render it as it likes.
  class GreetingMetricsQuery
    def initialize(vault:, date_range: nil)
      @vault = vault
      @date_range = date_range || (30.days.ago..Time.current)
    end

    def execute
      scope = @vault.greetings.where(created_at: @date_range)

      total = scope.count
      unlocked = scope.unlocked
      unlocked_count = unlocked.count
      opened_in_window = unlocked.where("unlocked_at >= scheduled_delivery_time")

      {
        total: total,
        unlocked: unlocked_count,
        locked: scope.locked.count,
        ready_to_unlock: scope.ready_to_unlock.count,
        open_rate: total.zero? ? 0.0 : (unlocked_count.to_f / total).round(3),
        mean_time_to_open_seconds: mean_time_to_open(opened_in_window),
        time_to_open_buckets: time_to_open_buckets(opened_in_window),
        animation_distribution: scope.group(:unlock_animation_type).count
      }
    end

    private

    def mean_time_to_open(scope)
      diffs = scope.pluck(:scheduled_delivery_time, :unlocked_at).map { |s, u| (u - s).to_i }
      return 0 if diffs.empty?

      (diffs.sum.to_f / diffs.size).round(0)
    end

    def time_to_open_buckets(scope)
      buckets = { within_1m: 0, within_1h: 0, within_1d: 0, later: 0 }
      scope.pluck(:scheduled_delivery_time, :unlocked_at).each do |sched, opened|
        diff = opened - sched
        if diff <= 60
          buckets[:within_1m] += 1
        elsif diff <= 3600
          buckets[:within_1h] += 1
        elsif diff <= 86_400
          buckets[:within_1d] += 1
        else
          buckets[:later] += 1
        end
      end
      buckets
    end
  end
end
