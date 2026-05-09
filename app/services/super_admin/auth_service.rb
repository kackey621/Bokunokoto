require "googleauth"
require "net/http"
require "json"

module SuperAdmin
  class AuthService
    def initialize
      @project_id = ENV.fetch("FIREBASE_PROJECT_ID", "bokuno-koto")
      
      # Use Application Default Credentials, which automatically picks up 
      # the GOOGLE_APPLICATION_CREDENTIALS environment variable.
      @authorizer = Google::Auth.get_application_default([
        "https://www.googleapis.com/auth/identitytoolkit",
        "https://www.googleapis.com/auth/cloud-platform"
      ])
    end

    def revoke_refresh_tokens(uid)
      url = URI("https://identitytoolkit.googleapis.com/v1/projects/#{@project_id}/accounts:revoke")
      post_request(url, { "localId" => uid })
    end

    def set_custom_claims(uid, claims)
      url = URI("https://identitytoolkit.googleapis.com/v1/projects/#{@project_id}/accounts:update")
      post_request(url, { "localId" => uid, "customAttributes" => claims.to_json })
    end

    private

    def post_request(url, body_hash)
      # Fetch a fresh access token using the service account credentials
      token = @authorizer.fetch_access_token!["access_token"]
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(url)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json"
      request.body = body_hash.to_json
      
      response = http.request(request)
      JSON.parse(response.body)
    end
  end
end
