module Bkc
  class VaultsController < BaseController
    skip_before_action :ensure_vault_accessible!, only: [ :create ]

    def index
      @vaults = current_user.owned_vaults.order(created_at: :asc)
      @active_vault = current_vault
    end

    def create
      vault = Vaults::CreateForOwner.new(
        owner: current_user,
        attributes: vault_params.to_h
      ).call

      current_user.update!(default_vault_id: vault.id) if current_user.default_vault_id.nil?

      redirect_to bkc_dashboard_path, notice: "Vault \"#{vault.display_name}\" created."
    rescue Vaults::QuotaExceeded => e
      redirect_to bkc_vaults_path, alert: "Vault quota reached (#{e.count}/#{e.limit})."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to bkc_dashboard_path, alert: "Error creating vault: #{e.record.errors.full_messages.join(', ')}"
    end

    def update
      vault = current_user.owned_vaults.find_by(id: params[:id]) || current_vault
      unless vault
        return redirect_to bkc_dashboard_path, alert: "Vault not found."
      end

      if vault.update(vault_params)
        redirect_to bkc_dashboard_path, notice: "Vault updated."
      else
        redirect_to bkc_dashboard_path, alert: "Error: #{vault.errors.full_messages.join(', ')}"
      end
    end

    private

    def vault_params
      params.require(:vault).permit(:display_name, :bio)
    end
  end
end
