module Api
  module V1
    module My
      class AnalyticsController < BaseController
        before_action :require_active_vault!

        def funnel
          query = Analytics::TrustFunnelQuery.new(vault: current_vault, date_range: date_range)
          render json: query.execute
        end

        def content
          query = Analytics::ContentEngagementQuery.new(vault: current_vault, date_range: date_range)
          render json: query.execute
        end

        def security
          logs = current_vault.audit_logs.where(occurred_at: date_range)

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

        def attribution
          query = Analytics::AccessLinkAttributionQuery.new(vault: current_vault, date_range: date_range)
          render json: query.execute
        end

        def accessibility
          query = Analytics::AccessibilityMetricsQuery.new(vault: current_vault, date_range: date_range)
          render json: query.execute
        end

        def greetings
          query = Analytics::GreetingMetricsQuery.new(vault: current_vault, date_range: date_range)
          render json: query.execute
        end

        private

        def require_active_vault!
          current_vault! # renders 409 when missing
        end

        def date_range
          # MEDIUM-017: malformed `start_date`/`end_date` params no longer
          # bubble Date::Error up to the API client.
          start_date = parse_date(params[:start_date]) || 30.days.ago
          end_date   = parse_date(params[:end_date])   || Time.current
          start_date..end_date
        end

        def parse_date(value)
          return nil if value.blank?
          Date.parse(value)
        rescue Date::Error, ArgumentError, TypeError
          nil
        end

        def failed_auth_count(logs)
          logs.where(action: [ "auth_failed", "token_invalid" ]).count
        end

        def gps_denial_count(logs)
          logs.where(action: "gps_denied").count
        end

        def face_capture_count(logs)
          logs.where.not(face_snapshot_url: nil).count
        end

        def detect_anomalies(logs)
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
end
