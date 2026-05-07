module Api
  module V1
    class HandshakeController < BaseController
      include AuditLoggable

      def create
        slug = params[:slug].to_s
        link = AccessLink.find_by(slug: slug)
        return render_error("not_found", :not_found) unless link

        if link.expired?
          return render_error("expired", :unprocessable_entity)
        elsif link.exhausted?
          return render_error("exhausted", :unprocessable_entity)
        elsif link.bound_to_other?(current_user)
          return render_error("link_already_bound", :forbidden)
        end

        permission = nil
        ActiveRecord::Base.transaction do
          link.claim!(current_user)
          permission = upsert_permission(link)
        end

        log_audit!(action: "handshake", vault: link.vault, user: current_user)

        render json: {
          status: "success",
          vault: { id: link.vault_id, display_name: link.vault.display_name },
          welcome_message: link.welcome_message,
          permission: { granted_level: permission.granted_level, status: permission.status }
        }
      end

      private

      def upsert_permission(link)
        permission = current_user.permissions.find_by(vault: link.vault)
        if permission
          # Don't lower an existing higher permission via re-handshake
          permission.update!(granted_level: [ permission.granted_level, link.initial_level ].max)
          permission
        else
          current_user.permissions.create!(
            vault: link.vault,
            granted_level: link.initial_level,
            relationship_context: link.preset_context,
            source_access_link_id: link.slug,
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
