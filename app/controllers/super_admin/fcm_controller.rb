module SuperAdmin
  class FcmController < BaseController
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
