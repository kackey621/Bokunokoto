module Bkc
  class VaultsController < BaseController
    def create
      if current_user.vault
        return redirect_to bkc_dashboard_path, alert: "You already have a vault."
      end

      vault = current_user.build_vault(vault_params)
      if vault.save
        redirect_to bkc_dashboard_path, notice: "Vault successfully initialized."
      else
        redirect_to bkc_dashboard_path, alert: "Error creating vault: #{vault.errors.full_messages.join(', ')}"
      end
    end

    private

    def vault_params
      params.require(:vault).permit(:display_name, :bio)
    end
  end
end
