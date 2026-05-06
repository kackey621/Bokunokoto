module Bkc
  class DashboardController < BaseController
    def show
      if current_vault
        @viewers_count = current_vault.viewers.count
        @contents_count = current_vault.contents.count
        @recent_activity = AuditLog
          .for_vault(current_vault)
          .recent
          .includes(:user, :content)
          .limit(10)
      else
        render "bkc/onboarding/new_vault"
      end
    end
  end
end
