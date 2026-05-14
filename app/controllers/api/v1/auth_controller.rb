module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: [ :verify ]

      def verify
        token = params[:token]
        return render json: { status: "error", message: "Invalid Firebase ID Token" }, status: :unauthorized if token.blank?

        payload = FirebaseIdToken::Signature.verify(token)

        if payload
          user = User.find_or_initialize_by(firebase_uid: payload["sub"])
          user.email = payload["email"]
          user.display_name = payload["name"] || payload["email"].split("@").first

          # Initialize capabilities for new users
          if user.new_record?
            user.role = "viewer"
            user.status = "active"
            user.trust_level = 0
            user.can_create_vault = true
            user.bkc_access = false
            user.is_beta_tester = false
          end

          if user.save
            render json: {
              status: "success",
              user: {
                id: user.id,
                firebase_uid: user.firebase_uid,
                email: user.email,
                display_name: user.display_name,
                role: user.role,
                trust_level: user.trust_level,
                vault: user.default_vault ? { id: user.default_vault.id, display_name: user.default_vault.display_name } : nil,
                capabilities: {
                  can_create_vault: user.can_create_vault,
                  bkc_access: user.bkc_access,
                  is_beta_tester: user.is_beta_tester
                }
              }
            }
          else
            render json: { status: "error", message: user.errors.full_messages.join(", ") }, status: :unprocessable_entity
          end
        else
          render json: { status: "error", message: "Invalid Firebase ID Token" }, status: :unauthorized
        end
      rescue FirebaseIdToken::Exceptions::NoCertificatesError
        render json: { status: "error", message: "Invalid Firebase ID Token" }, status: :unauthorized
      end
    end
  end
end
