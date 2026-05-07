module Analytics
  # Surfaces accessibility-related signals from the vault's audit log.
  # Today the audit log only carries view-level events (`AuditLog::ACTIONS`),
  # so what we can compute is intentionally coarse: per-format view shares
  # plus the share of contents marked with each `symbol_type`. As the SDK
  # adds finer-grained accessibility actions (secure-audio block, screen
  # reader engaged), they should be surfaced here without changing the
  # response shape.
  class AccessibilityMetricsQuery
    def initialize(vault:, date_range: nil)
      @vault = vault
      @date_range = date_range || (30.days.ago..Time.current)
    end

    def execute
      contents = @vault.contents
      view_logs = @vault.audit_logs.where(action: "view", occurred_at: @date_range).includes(:content)

      {
        format_views: format_view_breakdown(view_logs),
        symbol_coverage: symbol_coverage(contents),
        summary: {
          total_views: view_logs.count,
          contents_with_symbols: contents.where.not(symbol_type: [ nil, "" ]).count,
          total_contents: contents.count
        }
      }
    end

    private

    def format_view_breakdown(view_logs)
      counts = view_logs.filter_map { |l| l.content&.format }.tally
      Content.validators_on(:format).flat_map { |v| v.options[:in] }.uniq.each_with_object({}) do |fmt, h|
        h[fmt] = counts.fetch(fmt, 0)
      end
    end

    def symbol_coverage(contents)
      contents.where.not(symbol_type: [ nil, "" ])
              .group(:symbol_type)
              .count
    end
  end
end
