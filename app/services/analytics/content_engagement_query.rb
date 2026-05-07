module Analytics
  class ContentEngagementQuery
    def initialize(vault:, date_range: nil)
      @vault = vault
      @date_range = date_range || (30.days.ago..Time.current)
    end

    def execute
      contents_data = @vault.contents.map do |content|
        {
          id: content.id,
          title: content.title,
          views: view_count(content),
          unique_viewers: unique_viewer_count(content),
          last_viewed: last_viewed_at(content)
        }
      end

      {
        contents: contents_data,
        summary: {
          total_views: total_views,
          total_unique_viewers: total_unique_viewers,
          most_viewed: contents_data.max_by { |c| c[:views] },
          most_recent: contents_data.max_by { |c| c[:last_viewed] || Time.at(0) }
        }
      }
    end

    private

    def view_count(content)
      AuditLog.where(content_id: content.id)
               .where(occurred_at: @date_range)
               .count
    end

    def unique_viewer_count(content)
      AuditLog.where(content_id: content.id)
               .where(occurred_at: @date_range)
               .distinct
               .count(:user_id)
    end

    def last_viewed_at(content)
      AuditLog.where(content_id: content.id)
               .order(occurred_at: :desc)
               .first
               &.occurred_at
    end

    def total_views
      AuditLog.where(vault_id: @vault.id)
               .where(occurred_at: @date_range)
               .count
    end

    def total_unique_viewers
      AuditLog.where(vault_id: @vault.id)
               .where(occurred_at: @date_range)
               .distinct
               .count(:user_id)
    end
  end
end
