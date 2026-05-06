module Console
  class SampleJob < ApplicationJob
    queue_as :default

    def perform(message = "Triggered from Rails system console")
      Rails.logger.info("[Console::SampleJob] #{message}")
    end
  end
end
