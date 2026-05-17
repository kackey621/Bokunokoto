require "googleauth"
require "net/http"
require "json"

module SuperAdmin
  class RemoteConfigService
    # HIGH-010: raised when Firebase rejects publish because the
    # If-Match ETag is stale. Controllers translate this into a
    # user-visible refresh prompt.
    class EtagMismatch < StandardError; end

    def initialize
      @project_id = SuperAdmin.firebase_project_id!
      @authorizer = Google::Auth.get_application_default([
        "https://www.googleapis.com/auth/firebase.remoteconfig"
      ])
    end

    # Returns { template: <parsed body>, etag: <header value> } so callers
    # can round-trip the etag back to #publish_template.
    def fetch_template
      url = URI("https://firebaseremoteconfig.googleapis.com/v1/projects/#{@project_id}/remoteConfig")

      token = @authorizer.fetch_access_token!["access_token"]

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(url)
      request["Authorization"] = "Bearer #{token}"

      response = http.request(request)
      { template: JSON.parse(response.body), etag: response["ETag"] }
    end

    # HIGH-010: requires the etag captured from a previous fetch_template
    # call. Passing "*" used to mask lost-update races where two
    # operators publish in parallel.
    def publish_template(template, etag:)
      raise ArgumentError, "etag is required (HIGH-010)" if etag.blank?

      url = URI("https://firebaseremoteconfig.googleapis.com/v1/projects/#{@project_id}/remoteConfig")

      token = @authorizer.fetch_access_token!["access_token"]

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      request = Net::HTTP::Put.new(url)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json"
      request["If-Match"] = etag
      request.body = template.to_json

      response = http.request(request)

      if response.code.to_i == 412
        raise EtagMismatch, "remote etag changed (was #{etag.inspect})"
      end

      JSON.parse(response.body)
    end
  end
end
