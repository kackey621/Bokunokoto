module Api
  module V1
    module My
      class VaultsController < BaseController
        def show
          if current_user.vault
            render json: {
              status: "success",
              vault: vault_response(current_user.vault)
            }
          else
            render json: { status: "error", message: "No vault found" }, status: :not_found
          end
        end

        def create
          unless current_user.can_create_vault
            return render_error("You do not have permission to create a vault", :forbidden)
          end

          if current_user.vault
            return render_error("You already have an active vault")
          end

          vault = current_user.build_vault(vault_params)
          assign_bank_account(vault)
          if vault.save
            render json: {
              status: "success",
              vault: vault_response(vault)
            }, status: :created
          else
            render_error(vault.errors.full_messages.join(", "))
          end
        end

        def update
          vault = current_user.vault
          return render_error("No vault found", :not_found) unless vault

          assign_bank_account(vault)
          vault.assign_attributes(vault_params)

          if vault.save
            render json: {
              status: "success",
              vault: vault_response(vault)
            }
          else
            render_error(vault.errors.full_messages.join(", "))
          end
        end

        private

        def vault_params
          params.require(:vault).permit(:display_name, :bio)
        end

        def assign_bank_account(vault)
          info = params.dig(:vault, :bank_account_info)
          return if info.blank?

          # Use the bank_account_data= setter so the Hash is serialized to
          # JSON before the encrypted column write. Assigning the Hash
          # directly to bank_account_info would call .to_s and produce
          # unparseable Ruby-syntax output.
          vault.bank_account_data = info.permit(
            :account_number, :bank_name, :routing_number
          ).to_h
        end

        def vault_response(vault)
          {
            id: vault.id,
            display_name: vault.display_name,
            bio: vault.bio,
            masked_account_number: vault.masked_account_number,
            bank_account_info: vault.bank_account_data
          }
        end
      end
    end
  end
end
