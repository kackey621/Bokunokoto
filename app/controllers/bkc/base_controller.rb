module Bkc
  class BaseController < ApplicationController
    layout "bkc"
    before_action :authenticate_bkc_user!
    before_action :ensure_vault_accessible!

    private

    def authenticate_bkc_user!
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

    def ensure_vault_accessible!
      return if current_user.nil?
      unless current_user.owned_vaults.exists? || current_user.can_create_vault
        redirect_to root_path, alert: "You do not have a vault and cannot create one."
      end
    end

    def current_user
      @current_user
    end

    # Resolves active vault for BKC via:
    #   1. bk_active_vault signed cookie
    #   2. users.default_vault_id / first owned vault
    def current_vault
      @current_vault ||= resolve_bkc_vault
    end

    def resolve_bkc_vault
      return nil unless current_user

      cookie_vault_id = cookies.signed[:bk_active_vault]
      if cookie_vault_id.present?
        vault = current_user.owned_vaults.find_by(id: cookie_vault_id)
        return vault if vault
      end

      current_user.default_vault
    end

    helper_method :current_user, :current_vault
  end
end
