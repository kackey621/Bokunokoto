module Analytics
  class TrustFunnelQuery
    def initialize(vault:, date_range: nil)
      @vault = vault
      @date_range = date_range || 30.days.ago..Time.current
    end

    def execute
      {
        labels: status_labels,
        counts: status_counts,
        summary: {
          total_permissions: total_permissions,
          active: active_count,
          pending: pending_count,
          suspended: suspended_count
        }
      }
    end

    private

    def status_labels
      %w[Pending Active Suspended]
    end

    def status_counts
      [pending_count, active_count, suspended_count]
    end

    def total_permissions
      @vault.permissions.count
    end

    def active_count
      @vault.permissions.where(status: "active").count
    end

    def pending_count
      @vault.permissions.where(status: "pending").count
    end

    def suspended_count
      @vault.permissions.where(status: "suspended").count
    end
  end
end
