module SuperAdmin
  class RemoteConfigController < BaseController
    def index
      service = SuperAdmin::RemoteConfigService.new
      begin
        @template = service.fetch_template
      rescue => e
        flash.now[:alert] = "Failed to fetch remote config: #{e.message}"
        @template = {}
      end
    end

    def create
      service = SuperAdmin::RemoteConfigService.new
      begin
        new_template = JSON.parse(params[:template_json])
        service.publish_template(new_template)
        flash[:notice] = "Remote configuration updated successfully."
      rescue JSON::ParserError
        flash[:alert] = "Invalid JSON format."
      rescue => e
        flash[:alert] = "Failed to update configuration: #{e.message}"
      end
      redirect_to super_admin_remote_config_index_path
    end
  end
end
