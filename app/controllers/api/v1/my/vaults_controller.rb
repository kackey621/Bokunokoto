module Api
  module V1
    module My
      class VaultsController < BaseController
        before_action :set_vault, only: [ :show, :update, :archive, :restore ]

        def index
          vaults = current_user.owned_vaults.active.order(created_at: :asc)
          render json: {
            status: "success",
            vaults: vaults.map { |v| vault_response(v) }
          }
        end

        def show
          render json: { status: "success", vault: vault_response(@vault) }
        end

        def create
          unless current_user.can_create_vault
            return render_error("You do not have permission to create a vault", :forbidden)
          end

          vault = Vaults::CreateForOwner.new(
            owner: current_user,
            attributes: vault_params.to_h
          ).call

          assign_bank_account(vault)
          vault.save! if vault.changed?

          current_user.update!(default_vault_id: vault.id) if current_user.default_vault_id.nil?

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
          assign_bank_account(@vault)
          @vault.assign_attributes(vault_params)

          if @vault.save
            render json: { status: "success", vault: vault_response(@vault) }
          else
            render_error(@vault.errors.full_messages.join(", "))
          end
        end

        def archive
          @vault.update!(archived_at: Time.current)
          render json: { status: "success", vault: vault_response(@vault) }
        end

        def restore
          @vault.update!(archived_at: nil)
          render json: { status: "success", vault: vault_response(@vault) }
        end

        private

        def set_vault
          @vault = current_user.owned_vaults.find_by(id: params[:id])
          render_error("Vault not found", :not_found) unless @vault
        end

        def vault_params
          params.require(:vault).permit(:display_name, :bio, :slug, :kind)
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
            slug: vault.slug,
            kind: vault.kind,
            archived_at: vault.archived_at,
            default_vault: current_user.default_vault_id == vault.id,
            # CRITICAL-001: bank_account_info plaintext is no longer
            # serialized. Only the masked account number is returned.
            masked_account_number: vault.masked_account_number
          }
        end
      end
    end
  end
end
