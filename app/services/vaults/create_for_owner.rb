module Vaults
  class CreateForOwner
    def initialize(owner:, attributes: {})
      @owner = owner
      @attributes = attributes
    end

    def call
      unless @owner.can_create_vault
        raise Vaults::QuotaExceeded.new(count: current_count, limit: 0)
      end

      if !@owner.platform_operator? && current_count >= quota
        raise Vaults::QuotaExceeded.new(count: current_count, limit: quota)
      end

      @owner.owned_vaults.create!(@attributes)
    end

    private

    def current_count
      @current_count ||= @owner.owned_vaults.count
    end

    def quota
      @owner.vault_quota
    end
  end
end
