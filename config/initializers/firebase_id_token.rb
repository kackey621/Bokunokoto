FirebaseIdToken.configure do |config|
  config.project_ids = [ ENV.fetch("FIREBASE_PROJECT_ID", "bokunokoto-prototype") ]
end
