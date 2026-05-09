namespace :admin do
  desc "Seed the admin database with an initial manager account"
  task seed: :environment do
    puts "Seeding admin database..."
    
    email = ENV.fetch("ADMIN_EMAIL", "admin@bokunokoto.app")
    password = ENV.fetch("ADMIN_PASSWORD", "password123")
    role = ENV.fetch("ADMIN_ROLE", "admin")

    manager = Manager.find_or_initialize_by(email: email)
    manager.password = password
    manager.role = role
    
    if manager.save
      puts "✅ Initial Manager created successfully."
      puts "   Email:    #{email}"
      puts "   Password: #{password}"
      puts "   Role:     #{role}"
    else
      puts "❌ Failed to create Manager:"
      manager.errors.full_messages.each do |msg|
        puts "   - #{msg}"
      end
    end
  end
end
