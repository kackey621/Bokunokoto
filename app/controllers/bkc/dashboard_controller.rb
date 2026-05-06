module Bkc
  class DashboardController < BaseController
    def show
      if current_vault
        @viewers_count = current_vault.viewers.count
        @contents_count = current_vault.contents.count
        @recent_activity = [] # Placeholder for audit logs
      else
        render "bkc/onboarding/new_vault"
      end
    end
  end
end
