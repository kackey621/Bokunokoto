module Bkc
  class ActiveVaultController < BaseController
    def create
      vault = current_user.owned_vaults.active.find_by(id: params[:vault_id])
      if vault
        set_active_vault!(vault)
      end
      redirect_back(fallback_location: bkc_dashboard_path)
    end
  end
end
