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

      def render_unauthorized(message)
        render json: { status: "error", message: message }, status: :unauthorized
      end

      def render_error(message, status = :unprocessable_entity)
        render json: { status: "error", message: message }, status: status
      end
    end
  end
end
