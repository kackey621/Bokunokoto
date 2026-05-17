module SuperAdmin
  class FcmController < BaseController
    # HIGH-009: only admins (not operators) may push to the FCM topic. The
    # AuditLog model requires a vault_id (NOT NULL) so platform-scoped
    # events go through Rails.logger with a structured tag instead.
    before_action :require_platform_admin!, only: :create

    def index
    end

    def create
      title = params[:title]
      body = params[:body]
      topic = params[:topic].presence || "all_users"

      if title.present? && body.present?
        service = SuperAdmin::FcmService.new
        begin
          service.send_announcement(title, body, topic: topic)
          Rails.logger.info(
            "[audit][fcm_announcement] " \
            "manager_id=#{current_manager.id} " \
            "role=#{current_manager.role} " \
            "topic=#{topic.inspect} " \
            "title=#{title.to_s.first(120).inspect} " \
            "body_len=#{body.to_s.length}"
          )
          flash[:notice] = "Announcement sent successfully."
        rescue => e
          flash[:alert] = "Failed to send announcement: #{e.message}"
        end
      else
        flash[:alert] = "Title and Body are required."
      end

      redirect_to super_admin_fcm_index_path
    end
  end
end
