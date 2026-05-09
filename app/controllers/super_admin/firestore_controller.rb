module SuperAdmin
  class FirestoreController < BaseController
    def index
      service = SuperAdmin::FirestoreService.new
      begin
        @tickets = service.fetch_recent_tickets
      rescue => e
        flash.now[:alert] = "Failed to fetch from Firestore: #{e.message}"
        @tickets = []
      end
    end
  end
end
