namespace :account do
  desc "Backfill permissions from legacy User.trust_level"
  task backfill_permissions: :environment do
    puts "Starting backfill of permissions..."
    
    # We need a target vault to backfill to. 
    # If there's only one vault in the system, we use that.
    # Otherwise, we ask the operator or skip.
    target_vault = Vault.first
    
    if target_vault.nil?
      puts "No vaults found. Skipping backfill."
      next
    end

    puts "Targeting vault: #{target_vault.display_name} (Owner: #{target_vault.user.display_name})"

    User.where.not(id: target_vault.user_id).find_each do |user|
      next if user.trust_level == 0
      
      permission = Permission.find_or_initialize_by(vault: target_vault, user: user)
      if permission.new_record?
        permission.granted_level = user.trust_level
        permission.status = "active"
        permission.relationship_context = "backfilled from legacy trust_level"
        
        if permission.save
          puts "Created permission for #{user.display_name} at L#{user.trust_level}"
        else
          puts "Failed to create permission for #{user.display_name}: #{permission.errors.full_messages.join(', ')}"
        end
      else
        puts "Permission already exists for #{user.display_name}. Skipping."
      end
    end
    
    puts "Backfill complete."
  end
end
