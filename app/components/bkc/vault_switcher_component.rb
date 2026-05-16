module Bkc
  class VaultSwitcherComponent < ViewComponent::Base
    def initialize(current_user:, current_vault:)
      @current_user = current_user
      @current_vault = current_vault
    end

    def owned_vaults
      @current_user.owned_vaults.active.order(:display_name)
    end

    def operator_context?
      @current_user.platform_operator? && @current_vault &&
        !@current_user.owns?(@current_vault)
    end
  end
end
