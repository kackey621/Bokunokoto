module Api
  module V1
    class HandshakeController < BaseController
      skip_before_action :authenticate_user!, only: [ :create ]

      def create
        slug = handshake_params[:slug]
        access_link = AccessLink.find_by(slug: slug)

        if access_link.nil?
          return render json: { error: 'Invalid access link' }, status: :not_found
        end

        unless access_link.valid_for_handshake?
          return render json: { error: 'Access link expired or max uses exceeded' }, status: :forbidden
        end

        firebase_uid = handshake_params[:firebase_uid]
        user = User.find_by(firebase_uid: firebase_uid)

        if user.nil?
          return render json: { error: 'User not found' }, status: :not_found
        end

        permission = find_or_create_permission(access_link.vault, user, access_link)
        access_link.use!

        render json: {
          permission: PermissionSerializer.new(permission).serializable_hash,
          vault: VaultSerializer.new(access_link.vault).serializable_hash,
          welcome_message: access_link.welcome_message,
          initial_level: access_link.initial_level,
          preset_context: access_link.preset_context
        }, status: :created
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
      def handshake_params
        params.require(:handshake).permit(:slug, :firebase_uid)
      end

      def find_or_create_permission(vault, user, access_link)
        permission = vault.permissions.find_by(user_id: user.id)

        if permission
          permission.update(source_access_link_id: access_link.id)
        else
          permission = vault.permissions.create(
            user_id: user.id,
            granted_level: access_link.initial_level,
            status: "active",
            source_access_link_id: access_link.id
          )
        end

        permission
      end
    end
  end
end
