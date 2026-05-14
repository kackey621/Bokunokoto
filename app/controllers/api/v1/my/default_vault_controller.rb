module Api
  module V1
    module My
      class DefaultVaultController < BaseController
        def update
          vault_id = params.dig(:default_vault, :vault_id) || params[:vault_id]
          vault = current_user.owned_vaults.find_by(id: vault_id)

          unless vault
            return render_error("Vault not found or not owned by you", :not_found)
          end

          current_user.update!(default_vault_id: vault.id)
          render json: {
            status: "success",
            default_vault_id: current_user.default_vault_id
          }
        end
      end
    end
  end
end
