module Api
  module V1
    class ProfilesController < BaseController
      def show
        render json: {
          status: "success",
          profile: profile_response(current_user)
        }
      end

      def update
        if current_user.update(profile_params)
          current_user.update(profile_completed_at: Time.current) if profile_complete?
          render json: {
            status: "success",
            profile: profile_response(current_user)
          }
        else
          render_error(current_user.errors.full_messages.join(", "))
        end
      end

      private

      def profile_params
        params.require(:profile).permit(:real_name, :relationship, :purpose_of_access)
      end

      def profile_complete?
        profile_params[:real_name].present? &&
          profile_params[:relationship].present? &&
          profile_params[:purpose_of_access].present?
      end

      def profile_response(user)
        {
          real_name: user.real_name,
          relationship: user.relationship,
          purpose_of_access: user.purpose_of_access,
          profile_completed: user.profile_completed_at.present?,
          profile_completed_at: user.profile_completed_at,
          face_verified: user.face_verified_at.present?,
          can_access_l2: user.profile_completed_at.present? && user.face_verified_at.present?
        }
      end
    end
  end
end
