# HIGH-012: Require an explicit FIREBASE_PROJECT_ID in production. A
# placeholder fallback there silently authenticates tokens against the
# wrong tenant. Dev/test keep a sentinel value so the boot path still
# works without env wiring.
project_id = if Rails.env.production?
  ENV.fetch("FIREBASE_PROJECT_ID")
else
  ENV.fetch("FIREBASE_PROJECT_ID", "bokunokoto-development")
end

FirebaseIdToken.configure do |config|
  config.project_ids = [ project_id ]
end
