require "sidekiq/api"

module Console
  class DashboardController < BaseController
    def show
      @user_summary = {
        total: User.count,
        active: User.where(status: "active").count,
        suspended: User.where(status: "suspended").count,
        admins: User.where(role: "admin").count
      }
      @checks = {
        rails: rails_status,
        mysql: mysql_status,
        redis: redis_status,
        sidekiq: sidekiq_status,
        mailpit: mailpit_status
      }
    end

    def enqueue_sample_job
      job = Console::SampleJob.perform_later("Triggered from Rails system console")
      redirect_to console_path, notice: "Sample job enqueued: #{job.job_id}"
    end

    def send_sample_mail
      ConsoleMailer.sample.deliver_later
      redirect_to console_path, notice: "Sample email queued for Mailpit."
    end

    private

    def rails_status
      ok_status("Rails is serving the system console.")
    end

    def mysql_status
      ActiveRecord::Base.connection.execute("SELECT 1")
      ok_status("Connected to #{ActiveRecord::Base.connection_db_config.database}.")
    rescue StandardError => error
      error_status(error)
    end

    def redis_status
      Sidekiq.redis { |connection| connection.call("PING") }
      ok_status("Redis is reachable via REDIS_URL.")
    rescue StandardError => error
      error_status(error)
    end

    def sidekiq_status
      stats = Sidekiq::Stats.new
      ok_status("Processed #{stats.processed} jobs. #{stats.enqueued} jobs are enqueued.")
    rescue StandardError => error
      error_status(error)
    end

    def mailpit_status
      ok_status("SMTP target is #{Rails.application.config.action_mailer.smtp_settings[:address]}:#{Rails.application.config.action_mailer.smtp_settings[:port]}.")
    rescue StandardError => error
      error_status(error)
    end

    def ok_status(message)
      { ok: true, message: message }
    end

    def error_status(error)
      { ok: false, message: "#{error.class}: #{error.message}" }
    end
  end
end
