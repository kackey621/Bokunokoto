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
              is_beta_tester: current_user.is_beta_tester,
              vault_quota: current_user.vault_quota
            },
            default_vault_id: current_user.default_vault_id,
            owned_vaults: current_user.owned_vaults.map { |v|
              {
                id: v.id,
                display_name: v.display_name,
                slug: v.slug,
                kind: v.kind,
                archived_at: v.archived_at
              }
            },
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
