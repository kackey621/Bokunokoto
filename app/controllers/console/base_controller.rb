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
        # TODO: wire to Firebase auth or add a development-only console login flow
        # For now, development can use X-Dev-User-Id header (set by Rails.env.development? check)
        user_id ||= request.headers["X-Dev-User-Id"] if Rails.env.development?
        User.find_by(id: user_id) if user_id
      end
    end
    helper_method :current_console_user
  end
end
