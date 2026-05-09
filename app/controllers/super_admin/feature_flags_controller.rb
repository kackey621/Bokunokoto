module SuperAdmin
  class FeatureFlagsController < BaseController
    def index
      @features = begin
        Flipper.features
      rescue
        []
      end
    end
  end
end
