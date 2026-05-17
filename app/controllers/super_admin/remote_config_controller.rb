module SuperAdmin
  class RemoteConfigController < BaseController
    # HIGH-008: operators can read the template but only admins can publish.
    before_action :require_platform_admin!, only: :create

    def index
      service = SuperAdmin::RemoteConfigService.new
      begin
        result = service.fetch_template
        @template = result[:template]
        @template_etag = result[:etag]
      rescue => e
        flash.now[:alert] = "Failed to fetch remote config: #{e.message}"
        @template = {}
        @template_etag = nil
      end
    end

    def create
      service = SuperAdmin::RemoteConfigService.new
      begin
        new_template = JSON.parse(params[:template_json])
        etag = params[:etag].presence
        # HIGH-010: use the etag round-tripped from #index. If it is
        # missing, refuse to publish rather than forcing "*" which would
        # clobber a peer's concurrent change.
        unless etag
          flash[:alert] = "Missing ETag — refresh the page and try again."
          return redirect_to super_admin_remote_config_index_path
        end
        service.publish_template(new_template, etag: etag)
        Rails.logger.info(
          "[audit][remote_config] publish by manager_id=#{current_manager.id} " \
          "role=#{current_manager.role} etag=#{etag}"
        )
        flash[:notice] = "Remote configuration updated successfully."
      rescue JSON::ParserError
        flash[:alert] = "Invalid JSON format."
      rescue SuperAdmin::RemoteConfigService::EtagMismatch => e
        flash[:alert] = "Configuration changed by another admin (#{e.message}). Please refresh and re-apply."
      rescue => e
        flash[:alert] = "Failed to update configuration: #{e.message}"
      end
      redirect_to super_admin_remote_config_index_path
    end
  end
end
