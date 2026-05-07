module Api
  module V1
    class HandshakeController < BaseController
      def create
        slug = params[:slug]
        access_link = AccessLink.find_by(slug: slug)

        return render_error("not_found", :not_found) if access_link.nil?
        return render_error("expired", :unprocessable_entity) if access_link.expired?
        return render_error("exhausted", :unprocessable_entity) if access_link.exhausted?

        unless access_link.claim!(current_user)
          return render_error("link_already_bound", :forbidden)
        end

        permission = upsert_permission(access_link)

        AuditLog.create!(
          user: current_user,
          vault: access_link.vault,
          action: "handshake",
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          occurred_at: Time.current
        )

        render json: {
          welcome_message: access_link.welcome_message,
          preset_context: access_link.preset_context,
          initial_level: access_link.initial_level,
          permission: {
            id: permission.id,
            granted_level: permission.granted_level,
            relationship_context: permission.relationship_context,
            vault_id: permission.vault_id
          }
        }
      end

      private

      def upsert_permission(link)
        permission = current_user.permissions.find_by(vault: link.vault)
        if permission
          permission.update!(granted_level: [ permission.granted_level, link.initial_level ].max)
          permission
        else
          current_user.permissions.create!(
            vault: link.vault,
            granted_level: link.initial_level,
            relationship_context: link.preset_context,
            source_access_link_id: link.id,
            status: "active"
          )
        end
      end

      def render_error(code, status)
        render json: { status: "error", code: code }, status: status
      end
    end
  end
end
