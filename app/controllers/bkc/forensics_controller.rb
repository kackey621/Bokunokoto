module Bkc
  class ForensicsController < BaseController
    before_action :require_vault
    before_action :require_user, only: :timeline

    FACE_ARCHIVE_PER_PAGE = 24

    def index
      @audit_logs = @vault.audit_logs.includes(:user, :content).order(occurred_at: :desc)
      @incidents = @vault.incidents.unresolved.recent.limit(10)

      apply_filters if params[:start_date].present? || params[:end_date].present?

      @face_logs = @audit_logs.where.not(face_snapshot_url: nil)
                              .page(params[:page])
                              .per(FACE_ARCHIVE_PER_PAGE)
    end

    def timeline
      @audit_logs = @vault.audit_logs
                          .where(user_id: @user.id)
                          .includes(:content)
                          .order(occurred_at: :desc)

      apply_filters if params[:start_date].present? || params[:end_date].present?

      @incidents = @vault.incidents
                         .where(user_id: @user.id)
                         .recent
                         .limit(20)
    end

    private

    def require_vault
      @vault = current_vault
      redirect_to bkc_dashboard_path, alert: "No active vault. Please create or select a vault." unless @vault
    end

    def require_user
      @user = User.find_by(id: params[:user_id])
      redirect_to bkc_forensics_path, alert: "User not found" unless @user
    end

    def apply_filters
      @audit_logs = @audit_logs.where(occurred_at: date_range)

      if params[:user_id].present? && action_name == "index"
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
