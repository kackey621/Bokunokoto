class AuditRetentionCleanupJob < ApplicationJob
  queue_as :default

  # LOW-031: AuditLog and Incident rows retain IP address, user agent,
  # latitude/longitude indefinitely. This job scrubs the PII columns on
  # rows older than the retention window so the access history is
  # preserved (action, vault, user, timestamp) but the location/network
  # fingerprint is dropped.
  RETENTION_WINDOW = (ENV.fetch("AUDIT_RETENTION_DAYS", "365").to_i).days

  def perform
    cutoff = RETENTION_WINDOW.ago
    return if RETENTION_WINDOW <= 0

    scrubbed_logs = AuditLog.where("occurred_at < ?", cutoff)
                            .where.not(ip_address: nil)
                            .or(
                              AuditLog.where("occurred_at < ?", cutoff)
                                      .where.not(user_agent: nil)
                            )
                            .or(
                              AuditLog.where("occurred_at < ?", cutoff)
                                      .where.not(latitude: nil)
                            )
                            .or(
                              AuditLog.where("occurred_at < ?", cutoff)
                                      .where.not(longitude: nil)
                            )
                            .update_all(
                              ip_address: nil,
                              user_agent: nil,
                              latitude: nil,
                              longitude: nil,
                              face_snapshot_url: nil
                            )

    scrubbed_incidents = Incident.where("created_at < ?", cutoff)
                                 .where(resolved: true)
                                 .update_all(context: nil)

    Rails.logger.info(
      "[audit_retention_cleanup] cutoff=#{cutoff.iso8601} " \
      "audit_log_rows_scrubbed=#{scrubbed_logs} " \
      "incident_rows_scrubbed=#{scrubbed_incidents}"
    )
  end
end
