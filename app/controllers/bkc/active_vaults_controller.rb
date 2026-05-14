module Bkc
  class ActiveVaultsController < BaseController
    skip_before_action :ensure_vault_accessible!

    def update
      vault_id = params[:vault_id]
      vault = current_user.owned_vaults.find_by(id: vault_id)

      unless vault
        redirect_back fallback_location: bkc_dashboard_path, alert: "Vault not found."
        return
      end

      cookies.signed[:bk_active_vault] = {
        value: vault.id,
        httponly: true,
        same_site: :lax
      }

      redirect_back fallback_location: bkc_dashboard_path, notice: "Switched to #{vault.display_name}."
    end
  end
end
