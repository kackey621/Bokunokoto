redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  config.on(:startup) do
    FirebaseIdToken::Certificates.request
    RefreshFirebaseCertificatesJob.set(wait: RefreshFirebaseCertificatesJob::REFRESH_INTERVAL).perform_later
  rescue => e
    Rails.logger.error("[sidekiq startup] Firebase certificate fetch failed: #{e.message}")
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
