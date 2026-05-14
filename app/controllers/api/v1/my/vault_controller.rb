module Api
  module V1
    module My
      # Deprecated singular /api/v1/my/vault — kept for one release cycle.
      # Clients should migrate to /api/v1/my/vaults.
      class VaultController < BaseController
        DEPRECATION_HEADERS = {
          "Deprecation" => "true",
          "Link" => '</api/v1/my/vaults>; rel="successor-version"'
        }.freeze

        before_action :log_deprecation_hit

        def show
          vault = current_user.default_vault
          return render_error("No vault found", :not_found) unless vault

          response.headers.merge!(DEPRECATION_HEADERS)
          render json: { status: "success", vault: vault_response(vault) }
        end

        def create
          if current_user.owned_vaults.count > 0
            response.headers.merge!(DEPRECATION_HEADERS)
            return render json: {
              status: "error",
              message: "Use POST /api/v1/my/vaults for multi-vault accounts"
            }, status: :conflict
          end

          unless current_user.can_create_vault
            return render_error("You do not have permission to create a vault", :forbidden)
          end

          vault = Vaults::CreateForOwner.new(
            owner: current_user,
            attributes: vault_params.to_h
          ).call

          assign_bank_account(vault)
          vault.save! if vault.changed?

          current_user.update!(default_vault_id: vault.id)

          response.headers.merge!(DEPRECATION_HEADERS)
          render json: { status: "success", vault: vault_response(vault) }, status: :created
        rescue Vaults::QuotaExceeded => e
          render json: {
            status: "error",
            message: "vault_quota_exceeded",
            count: e.count,
            limit: e.limit
          }, status: :unprocessable_entity
        rescue ActiveRecord::RecordInvalid => e
          render_error(e.record.errors.full_messages.join(", "))
        end

        def update
          vault = current_user.default_vault
          return render_error("No vault found", :not_found) unless vault

          assign_bank_account(vault)
          vault.assign_attributes(vault_params)

          if vault.save
            response.headers.merge!(DEPRECATION_HEADERS)
            render json: { status: "success", vault: vault_response(vault) }
          else
            render_error(vault.errors.full_messages.join(", "))
          end
        end

        private

        def log_deprecation_hit
          Rails.logger.warn(
            "[DEPRECATION] /api/v1/my/vault (singular) hit — " \
            "action=#{action_name} " \
            "user_id=#{current_user&.id} " \
            "user_agent=#{request.user_agent.to_s.first(120).inspect} " \
            "bk_client_version=#{request.headers['X-BK-Client-Version'].inspect}"
          )
        end

        def vault_params
          params.require(:vault).permit(:display_name, :bio)
        end

        def assign_bank_account(vault)
          info = params.dig(:vault, :bank_account_info)
          return if info.blank?

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
