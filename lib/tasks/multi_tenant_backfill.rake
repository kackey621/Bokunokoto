# MT-15: Backfill default_vault_id for existing users who own exactly one vault.
# Idempotent — safe to re-run.
#
# Usage:
#   bin/rails multi_tenant:backfill_default_vault            # dry-run (default)
#   bin/rails multi_tenant:backfill_default_vault DRY_RUN=false

namespace :multi_tenant do
  desc "Backfill default_vault_id for users who own exactly one vault (dry-run by default)"
  task backfill_default_vault: :environment do
    dry_run = ENV.fetch("DRY_RUN", "true") != "false"

    puts dry_run ? "[DRY RUN] No changes will be written." : "[LIVE] Writing changes to the database."
    puts

    updated = 0
    skipped_already_set = 0
    skipped_multi = 0
    skipped_none = 0

    User.find_each do |user|
      if user.default_vault_id.present?
        skipped_already_set += 1
        next
      end

      vaults = user.owned_vaults.to_a

      case vaults.size
      when 0
        skipped_none += 1
      when 1
        vault = vaults.first
        unless dry_run
          user.update_column(:default_vault_id, vault.id)
        end
        puts "  [#{'DRY' if dry_run}] Set default_vault_id=#{vault.id} for user #{user.id} (#{user.email})"
        updated += 1
      else
        skipped_multi += 1
      end
    end

    puts
    puts "Summary:"
    puts "  Updated          : #{updated}"
    puts "  Skipped (already set)  : #{skipped_already_set}"
    puts "  Skipped (0 vaults)     : #{skipped_none}"
    puts "  Skipped (2+ vaults, needs manual resolution): #{skipped_multi}"
  end
end
