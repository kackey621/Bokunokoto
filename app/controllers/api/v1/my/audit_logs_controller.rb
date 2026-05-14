module Api
  module V1
    module My
      class AuditLogsController < BaseController
        before_action :require_active_vault!

        def index
          logs = AuditLog
            .for_vault(current_vault)
            .recent
            .includes(:user, :content)
            .limit(limit_param)

          render json: {
            status: "success",
            audit_logs: logs.map { |log| serialize(log) }
          }
        end

        private

        def require_active_vault!
          current_vault!
        end

        def limit_param
          raw = params.fetch(:limit, 100).to_i
          raw.clamp(1, 500)
        end

        def serialize(log)
          {
            id: log.id,
            action: log.action,
            occurred_at: log.occurred_at,
            user: { id: log.user_id, display_name: log.user.display_name },
            content: log.content && { id: log.content_id, title: log.content.title },
            ip_address: log.ip_address
          }
        end
      end
    end
  end
end
