class Rack::Attack
  # In test we use a memory store so throttle counts are isolated and
  # not dependent on Redis being available. In dev/prod, Rails.cache
  # (Redis-backed in production) is used.
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?

  # Block obviously bad requests entirely (still counts as a request, but
  # short-circuits before any controller work).
  blocklist("block bad UAs") do |req|
    req.user_agent.to_s.match?(/curl|wget|libwww-perl|nikto|sqlmap/i) && req.path.start_with?("/api/")
  end

  # Auth verification: 5 attempts per minute per IP. Brute-forcing tokens
  # against /auth/verify is the highest-risk surface; everything else needs
  # an already-valid token to even reach the controller.
  throttle("auth/verify by IP", limit: 5, period: 60) do |req|
    req.ip if req.path == "/api/v1/auth/verify" && req.post?
  end

  # Handshake (slug claim): 10 per minute per IP. Slug guessing is the
  # main reason rate limiting matters here — usable_by? leaks no slug
  # state, but enumeration speed should be capped.
  throttle("handshake by IP", limit: 10, period: 60) do |req|
    req.ip if req.path == "/api/v1/handshake" && req.post?
  end

  # Content reads: 60 per minute per IP. High enough to not surprise
  # legitimate viewers, low enough to be uninteresting for scrapers.
  throttle("content reads by IP", limit: 60, period: 60) do |req|
    req.ip if req.path =~ %r{\A/api/v1/(?:vaults/\d+/)?contents} && req.get?
  end

  # Use 429 with Retry-After so clients can back off gracefully.
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"] || {}
    retry_after = (match_data[:period] || 60).to_s

    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after },
      [ { status: "error", code: "rate_limited", retry_after: retry_after.to_i }.to_json ]
    ]
  end
end

Rails.application.config.middleware.use Rack::Attack
