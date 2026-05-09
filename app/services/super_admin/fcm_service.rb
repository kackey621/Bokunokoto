require "google/apis/fcm_v1"

module SuperAdmin
  class FcmService
    def initialize
      @project_id = ENV.fetch("FIREBASE_PROJECT_ID", "bokuno-koto")
      @client = Google::Apis::FcmV1::FirebaseCloudMessagingService.new
      @client.authorization = Google::Auth.get_application_default([
        "https://www.googleapis.com/auth/firebase.messaging"
      ])
    end

    def send_announcement(title, body, topic: "all_users")
      payload = Google::Apis::FcmV1::Message.new(
        topic: topic,
        notification: Google::Apis::FcmV1::Notification.new(
          title: title,
          body: body
        )
      )
      
      request = Google::Apis::FcmV1::SendMessageRequest.new(
        message: payload
      )
      
      parent = "projects/#{@project_id}"
      @client.send_message(parent, request)
    end
  end
end
