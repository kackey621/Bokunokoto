module Api
  module V1
    class AnalyticsController < BaseController
      def funnel
        vault = current_user.vault
        return render_error("No vault found", :not_found) unless vault

        query = Analytics::TrustFunnelQuery.new(vault: vault, date_range: date_range)
        render json: query.execute
      end

      def content
        vault = current_user.vault
        return render_error("No vault found", :not_found) unless vault

        query = Analytics::ContentEngagementQuery.new(vault: vault, date_range: date_range)
        render json: query.execute
      end

      def security
        vault = current_user.vault
        return render_error("No vault found", :not_found) unless vault

        logs = vault.audit_logs.where(occurred_at: date_range)

        render json: {
          total_accesses: logs.count,
          failed_auth_attempts: failed_auth_count(logs),
          gps_denials: gps_denial_count(logs),
          face_captures: face_capture_count(logs),
          summary: {
            secure_accesses: logs.count - failed_auth_count(logs),
            anomalies: detect_anomalies(logs)
          }
        }
      end

      private

      def date_range
        start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago
        end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Time.current
        start_date..end_date
      end

      def failed_auth_count(logs)
        # Count logs with auth-related failures
        logs.where(action: [ "auth_failed", "token_invalid" ]).count
      end

      def gps_denial_count(logs)
        logs.where(action: "gps_denied").count
      end

      def face_capture_count(logs)
        logs.where.not(face_snapshot_url: nil).count
      end

      def detect_anomalies(logs)
        # Simple anomaly detection: rapid access within short time
        user_accesses = logs.group_by(:user_id)
        anomalies = 0

        user_accesses.each do |_user_id, accesses|
          sorted = accesses.sort_by(&:occurred_at)
          sorted.each_with_index do |log, index|
            next if index == 0
            time_diff = (log.occurred_at - sorted[index - 1].occurred_at).abs
            anomalies += 1 if time_diff < 1.minute
          end
        end

        anomalies
      end
    end
  end
end
