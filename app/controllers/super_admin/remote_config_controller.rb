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
      # Placeholder for publishing a new template
      flash[:notice] = "Template updated (placeholder)."
      redirect_to super_admin_remote_config_index_path
    end
  end
end
