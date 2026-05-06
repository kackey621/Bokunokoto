module Bkc
  class BaseController < ApplicationController
    layout "bkc"
    before_action :authenticate_bkc_user!
    before_action :ensure_vault_exists!

    private

    def authenticate_bkc_user!
      # Placeholder for actual session/Firebase auth
      # For now, we'll try to find a user from session or fallback to first user in dev
      user_id = session[:user_id]
      user_id ||= request.headers["X-Test-User-Id"] if Rails.env.test?

      @current_user = User.find_by(id: user_id)

      if Rails.env.development? && !@current_user
        @current_user = User.first
      end

      unless @current_user
        redirect_to root_path, alert: "Please log in to access BKC."
      end
    end

    def ensure_vault_exists!
      unless current_user.vault || current_user.can_create_vault
        redirect_to root_path, alert: "You do not have a vault and cannot create one."
      end
    end

    def current_user
      @current_user
    end

    def current_vault
      @current_vault ||= current_user.vault
    end
    helper_method :current_user, :current_vault
  end
end
