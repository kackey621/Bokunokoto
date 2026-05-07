module Bkc
  class AnalyticsController < BaseController
    before_action :require_vault

    def show
      @date_range = params[:date_range] || "30"
      start_date = @date_range.to_i.days.ago

      @trust_funnel = Analytics::TrustFunnelQuery.new(
        vault: @vault,
        date_range: start_date..Time.current
      ).execute

      @engagement = Analytics::ContentEngagementQuery.new(
        vault: @vault,
        date_range: start_date..Time.current
      ).execute

      @security = fetch_security_metrics(start_date)
      @access_locations = fetch_access_locations(start_date)
    end

    def locations
      @vault = current_user.vault
      return render json: { error: "No vault found" }, status: :not_found unless @vault

      start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago
      end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Time.current

      logs = @vault.audit_logs.where(occurred_at: start_date..end_date)
                   .where.not(latitude: nil, longitude: nil)
                   .includes(:user)
                   .select(:id, :user_id, :latitude, :longitude, :occurred_at)

      render json: logs.map { |log|
        {
          id: log.id,
          user_id: log.user_id,
          user_name: log.user.display_name,
          latitude: log.latitude,
          longitude: log.longitude,
          occurred_at: log.occurred_at
        }
      }
    end

    private

    def require_vault
      @vault = current_user.vault
      redirect_to bkc_dashboard_path, alert: "No vault found" unless @vault
    end

    def fetch_security_metrics(start_date)
      logs = @vault.audit_logs.where("occurred_at >= ?", start_date)

      {
        total_accesses: logs.count,
        failed_auth_attempts: logs.where(action: ["auth_failed", "token_invalid"]).count,
        gps_denials: logs.where(action: "gps_denied").count,
        face_captures: logs.where.not(face_snapshot_url: nil).count,
        incidents: @vault.incidents.where("created_at >= ?", start_date).count
      }
    end

    def fetch_access_locations(start_date)
      @vault.audit_logs.where("occurred_at >= ?", start_date)
            .where.not(latitude: nil, longitude: nil)
            .includes(:user)
            .limit(100)
    end
  end
end
