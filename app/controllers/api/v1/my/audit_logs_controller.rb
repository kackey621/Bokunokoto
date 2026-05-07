module Api
  module V1
    module My
      class AuditLogsController < BaseController
        before_action :authenticate_user!

        def index
          vault = current_user.vault
          return render json: { status: "error", message: "no_vault" }, status: :not_found unless vault

          logs = AuditLog.where(content: vault.contents)
                         .order(occurred_at: :desc)
                         .limit(100)
          render json: { status: "success", audit_logs: logs.map { |l| serialize(l) } }
        end

        private

        def serialize(log)
          {
            id: log.id,
            content_id: log.content_id,
            user_id: log.user_id,
            action: log.action,
            ip_address: log.ip_address,
            occurred_at: log.occurred_at
          }
        end
      end
    end
  end
end
