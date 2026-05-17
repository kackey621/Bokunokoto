module SuperAdmin
  # HIGH-012: shared resolver so all five SuperAdmin service classes use
  # the same env contract and raise the same way in production when the
  # Firebase project id is missing.
  def self.firebase_project_id!
    if Rails.env.production?
      ENV.fetch("FIREBASE_PROJECT_ID")
    else
      ENV.fetch("FIREBASE_PROJECT_ID", "bokunokoto-development")
    end
  end
end
