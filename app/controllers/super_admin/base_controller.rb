module SuperAdmin
  class BaseController < ApplicationController
    layout "super_admin"
    before_action :authenticate_super_admin!

    private

    def authenticate_super_admin!
      # We assume current_user is available via some auth logic (e.g., from ApplicationController or Session)
      # For now, let's mock it if it's not defined, or assume we have a way to verify platform_admin?
      # In a real scenario, Devise or Firebase ID Token verification handles this.
      if defined?(current_user) && current_user
        unless current_user.platform_admin?
          render plain: "Unauthorized - Super Admin access required", status: :unauthorized
        end
      else
        render plain: "Unauthorized - Please sign in", status: :unauthorized
      end
    end
  end
end
