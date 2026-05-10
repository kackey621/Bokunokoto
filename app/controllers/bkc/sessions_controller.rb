module Bkc
  class SessionsController < BaseController
    skip_before_action :ensure_vault_exists!
    
    def destroy
      session[:user_id] = nil
      redirect_to root_path, notice: "Signed out from BKC successfully."
    end
  end
end
