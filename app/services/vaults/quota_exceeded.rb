module Vaults
  class QuotaExceeded < StandardError
    attr_reader :count, :limit

    def initialize(count:, limit:)
      @count = count
      @limit = limit
      super("Vault quota exceeded (#{count}/#{limit})")
    end
  end
end
