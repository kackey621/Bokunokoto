allowed_origins = ENV.fetch("FRONTEND_ORIGINS", "http://localhost:5173,http://localhost:3001")
  .split(",")
  .map(&:strip)
  .reject(&:blank?)

ALLOWED_REQUEST_HEADERS = %w[
  Accept
  Accept-Language
  Authorization
  Content-Language
  Content-Type
  Origin
  X-BK-Client-Version
  X-CSRF-Token
  X-Requested-With
].freeze

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "/api/*",
      headers: ALLOWED_REQUEST_HEADERS,
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization],
      max_age: 600
  end
end
