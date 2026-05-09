require "googleauth"
require "net/http"
require "json"

module SuperAdmin
  class RemoteConfigService
    def initialize
      @project_id = ENV.fetch("FIREBASE_PROJECT_ID", "bokuno-koto")
      @authorizer = Google::Auth.get_application_default([
        "https://www.googleapis.com/auth/firebase.remoteconfig"
      ])
    end

    def fetch_template
      url = URI("https://firebaseremoteconfig.googleapis.com/v1/projects/#{@project_id}/remoteConfig")
      
      token = @authorizer.fetch_access_token!["access_token"]
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(url)
      request["Authorization"] = "Bearer #{token}"
      
      response = http.request(request)
      JSON.parse(response.body)
    end

    def publish_template(template)
      url = URI("https://firebaseremoteconfig.googleapis.com/v1/projects/#{@project_id}/remoteConfig")
      
      token = @authorizer.fetch_access_token!["access_token"]
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      
      request = Net::HTTP::Put.new(url)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json"
      request["If-Match"] = "*" # Use actual ETag in production if required, or '*' to force overwrite
      request.body = template.to_json
      
      response = http.request(request)
      JSON.parse(response.body)
    end
  end
end
