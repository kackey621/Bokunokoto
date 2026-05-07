class RefreshFirebaseCertificatesJob < ApplicationJob
  queue_as :default

  REFRESH_INTERVAL = 55.minutes
  RETRY_INTERVAL = 5.minutes

  def perform
    FirebaseIdToken::Certificates.request
    self.class.set(wait: REFRESH_INTERVAL).perform_later
  rescue => e
    Rails.logger.error("[RefreshFirebaseCertificatesJob] Failed to fetch Firebase certificates: #{e.message}")
    self.class.set(wait: RETRY_INTERVAL).perform_later
  end
end
