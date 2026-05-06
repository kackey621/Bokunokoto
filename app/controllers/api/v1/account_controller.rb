module Api
  module V1
    class AccountController < BaseController
      def context
        render json: {
          status: "success",
          account: {
            capabilities: {
              can_create_vault: current_user.can_create_vault,
              bkc_access: current_user.bkc_access,
              is_beta_tester: current_user.is_beta_tester
            },
            owned_vault: current_user.vault ? {
              id: current_user.vault.id,
              display_name: current_user.vault.display_name
            } : nil,
            received_vaults: current_user.permissions.includes(:vault).map { |p|
              {
                id: p.vault.id,
                display_name: p.vault.display_name,
                trust_level: p.granted_level,
                status: p.status
              }
            }
          }
        }
      end
    end
  end
end
