module Analytics
  # Per-AccessLink attribution: how many viewers each link originated,
  # and what trust level they reached. "Clicks" here means successful
  # handshakes (a Permission is created with source_access_link_id set);
  # we cannot count handshake attempts that failed at the slug-validation
  # stage because those never reach the Permission table.
  class AccessLinkAttributionQuery
    def initialize(vault:, date_range: nil)
      @vault = vault
      @date_range = date_range || (30.days.ago..Time.current)
    end

    def execute
      links = @vault.access_links.includes(:permissions)

      attributions = links.map { |link| build_row(link) }

      {
        attributions: attributions,
        summary: {
          total_links: links.count,
          total_conversions: attributions.sum { |a| a[:clicks] },
          total_l1_conversions: attributions.sum { |a| a[:l1_conversions] },
          total_l2_conversions: attributions.sum { |a| a[:l2_conversions] }
        }
      }
    end

    private

    def build_row(link)
      permissions = Permission.where(source_access_link_id: link.id, created_at: @date_range)

      {
        link_id: link.id,
        slug: link.slug,
        preset_context: link.preset_context,
        clicks: permissions.count,
        l1_conversions: permissions.where("granted_level >= ?", 1).count,
        l2_conversions: permissions.where("granted_level >= ?", 2).count,
        bound_user_id: link.bound_user_id,
        use_count: link.use_count,
        max_uses: link.max_uses,
        expires_at: link.expires_at
      }
    end
  end
end
