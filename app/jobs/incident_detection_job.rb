class IncidentDetectionJob
  include Sidekiq::Worker
  sidekiq_options retry: 3

  def perform
    Vault.find_each do |vault|
      vault.permissions.find_each do |permission|
        user = permission.user
        IncidentDetectorService.analyze_user_activity(vault, user)
      end
    end
  end
end
