module Api
  module V1
    class HealthController < BaseController
      skip_before_action :authenticate_user!

      def show
        render json: {
          status: "ok",
          service: "bokunokoto-api"
        }
      end
    end
  end
end
