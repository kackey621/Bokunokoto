module SuperAdmin
  class FirestoreService
    def initialize
      # Configuration for google-cloud-firestore
      @project_id = SuperAdmin.firebase_project_id!
      @firestore = Google::Cloud::Firestore.new(project_id: @project_id)
    end

    def fetch_user_support_data(user_id)
      @firestore.col("support_tickets").where(:user_id, :==, user_id).get
    end

    def fetch_recent_tickets(limit = 50)
      @firestore.col("support_tickets").order(:created_at, :desc).limit(limit).get
    end

    def update_document(collection, document_id, data)
      @firestore.col(collection).doc(document_id).set(data, merge: true)
    end
  end
end
