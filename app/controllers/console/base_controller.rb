module Console
  class BaseController < ApplicationController
    layout "console"

    before_action :require_platform_admin!

    private

    def require_platform_admin!
      user = current_console_user
      return if user&.platform_admin?

      respond_to do |format|
        format.html { render plain: "Platform admin access required.", status: :forbidden }
        format.json { render json: { status: "error", message: "Platform admin access required." }, status: :forbidden }
        format.turbo_stream { render plain: "Platform admin access required.", status: :forbidden }
        format.any { render plain: "Platform admin access required.", status: :forbidden }
      end
    end

    def current_console_user
      @current_console_user ||= begin
        user_id = session[:user_id]
        user_id ||= request.headers["X-Test-User-Id"] if Rails.env.test?
        # CRITICAL-002: only honour the X-Dev-User-Id header in development
        # when an explicit opt-in env var is set. Without this gate, a
        # misconfigured production deploy with RAILS_ENV=development would
        # accept the header as authentication.
        if Rails.env.development? && ENV["ALLOW_DEV_AUTH_BYPASS"] == "1"
          user_id ||= request.headers["X-Dev-User-Id"]
        end
        User.find_by(id: user_id) if user_id
      end
    end
    helper_method :current_console_user
  end
end
