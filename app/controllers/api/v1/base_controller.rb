module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_user!

      private

      def authenticate_user!
        token = request.headers["Authorization"]&.split(" ")&.last
        return render_unauthorized("Invalid or missing Firebase ID Token") if token.blank?

        payload = FirebaseIdToken::Signature.verify(token)

        if payload
          @current_user = User.find_by(firebase_uid: payload["sub"])
          render_unauthorized("User not found in database") unless @current_user
        else
          render_unauthorized("Invalid or missing Firebase ID Token")
        end
      rescue FirebaseIdToken::Exceptions::NoCertificatesError
        render_unauthorized("Invalid or missing Firebase ID Token")
      end

      def current_user
        @current_user
      end

      # Resolves the active vault for the current user via:
      #   1. route :vault_id param
      #   2. X-BK-Active-Vault request header
      #   3. users.default_vault_id / first owned vault
      # Returns nil when no vault is resolvable.
      def current_vault
        @current_vault ||= resolve_active_vault
      end

      # Like current_vault but renders 409 when none is resolved.
      # Uses performed? to avoid double-render when resolve_active_vault
      # already rendered (e.g. vault_not_found, archived vault).
      def current_vault!
        vault = current_vault
        return vault if vault
        render_active_vault_required unless performed?
        nil
      end

      def resolve_active_vault
        return nil unless current_user

        vault_id = params[:vault_id].presence ||
                   request.headers["X-BK-Active-Vault"].presence

        if vault_id.present?
          vault = current_user.owned_vaults.find_by(id: vault_id)
          if vault
            return render_active_vault_required if vault.archived?
            return vault
          end

          # Might be a vault shared with the user via permissions.
          permitted = current_user.accessible_vaults.find_by(id: vault_id)
          return permitted if permitted

          render json: { status: "error", message: "vault_not_found" }, status: :not_found
          return nil
        end

        current_user.default_vault
      end

      def render_active_vault_required
        owned = current_user.owned_vaults.map { |v| { id: v.id, display_name: v.display_name } }
        render json: {
          status: "error",
          message: "active_vault_required",
          owned_vaults: owned
        }, status: :conflict
        nil
      end

      def render_unauthorized(message)
        render json: { status: "error", message: message }, status: :unauthorized
      end

      def render_error(message, status = :unprocessable_entity)
        render json: { status: "error", message: message }, status: status
      end
    end
  end
end
