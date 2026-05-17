module SuperAdmin
  class BaseController < ApplicationController
    layout "super_admin"
    before_action :authenticate_super_admin!

    private

    def authenticate_super_admin!
      manager_id = session[:manager_id]
      manager_id ||= request.headers["X-Test-Manager-Id"] if Rails.env.test?

      @current_manager = Manager.find_by(id: manager_id)

      # CRITICAL-002: dev auto-impersonation as `Manager.first` is now
      # opt-in only. Without this, a misconfigured prod deploy
      # (RAILS_ENV=development) would silently hand out manager access.
      if Rails.env.development? && !@current_manager && ENV["ALLOW_DEV_AUTH_BYPASS"] == "1" && Manager.exists?
        @current_manager = Manager.first
        session[:manager_id] = @current_manager.id
      end

      if @current_manager
        unless @current_manager.platform_admin? || @current_manager.platform_operator?
          redirect_to new_super_admin_session_path, alert: "Unauthorized - Super Admin access required"
        end
      else
        redirect_to new_super_admin_session_path, alert: "Please sign in to access the Super Admin console"
      end
    end

    # HIGH-008 / HIGH-009: stricter gate that only admits `platform_admin`
    # managers (Manager.role == "admin"). The default
    # `authenticate_super_admin!` admits both roles for read access.
    def require_platform_admin!
      unless @current_manager&.platform_admin?
        redirect_to super_admin_root_path,
                    alert: "Platform admin access required for this action."
      end
    end

    def current_manager
      @current_manager
    end
    helper_method :current_manager
  end
end
