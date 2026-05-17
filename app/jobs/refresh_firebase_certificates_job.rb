class RefreshFirebaseCertificatesJob < ApplicationJob
  queue_as :default

  REFRESH_INTERVAL = 55.minutes
  RETRY_INTERVAL = 5.minutes
  # LOW-033: stop chaining after this many consecutive failures and emit
  # a loud Rails.logger.error so the on-call team can pick it up. The
  # next successful run resets the counter.
  MAX_CONSECUTIVE_FAILURES = 5
  FAILURE_COUNTER_KEY = "refresh_firebase_certificates_job:failures".freeze

  def perform
    FirebaseIdToken::Certificates.request
    Rails.cache.delete(FAILURE_COUNTER_KEY)
    self.class.set(wait: REFRESH_INTERVAL).perform_later
  rescue => e
    failures = Rails.cache.increment(FAILURE_COUNTER_KEY, 1, expires_in: 24.hours) || 1
    Rails.logger.error(
      "[RefreshFirebaseCertificatesJob] fetch failed (attempt #{failures}/#{MAX_CONSECUTIVE_FAILURES}): #{e.message}"
    )

    if failures >= MAX_CONSECUTIVE_FAILURES
      Rails.logger.error(
        "[RefreshFirebaseCertificatesJob] ALERT: #{failures} consecutive failures, " \
        "stopping retry chain. Investigate Firebase certificate refresh manually."
      )
      return
    end

    self.class.set(wait: RETRY_INTERVAL).perform_later
  end
end
