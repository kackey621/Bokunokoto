module Bkc
  class ForensicsController < BaseController
    before_action :require_vault

    def index
      @audit_logs = @vault.audit_logs.includes(:user, :content).order(occurred_at: :desc)
      @incidents = @vault.incidents.unresolved.recent.limit(10)

      apply_filters if params[:start_date].present? || params[:end_date].present?
    end

    private

    def require_vault
      @vault = current_user.vault
      redirect_to bkc_dashboard_path, alert: "No vault found" unless @vault
    end

    def apply_filters
      @audit_logs = @audit_logs.where(occurred_at: date_range)

      if params[:user_id].present?
        @audit_logs = @audit_logs.where(user_id: params[:user_id])
      end
    end

    def date_range
      start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago
      end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Time.current
      start_date..end_date
    end
  end
end
