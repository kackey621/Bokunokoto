module VaultResolution
  extend ActiveSupport::Concern

  included do
    helper_method :current_vault if respond_to?(:helper_method)
  end

  FOREIGN_VAULT_SENTINEL = :foreign_vault_sentinel

  def current_vault
    @current_vault ||= begin
      result = resolve_active_vault
      if result == FOREIGN_VAULT_SENTINEL
        handle_foreign_vault
        nil
      else
        result
      end
    end
  end

  def current_vault!
    vault = current_vault
    # handle_foreign_vault may have already rendered a response
    return nil if performed?

    unless vault
      handle_missing_vault
    end
    vault
  end

  private

  def resolve_active_vault
    vault_id = params[:vault_id].presence ||
               request.headers["X-BK-Active-Vault"].presence

    if vault_id
      vault = current_user.owned_vaults.active.find_by(id: vault_id)
      vault || FOREIGN_VAULT_SENTINEL
    else
      current_user.default_vault
    end
  end

  # Override in including controller to customize error handling.
  def handle_missing_vault
    raise NotImplementedError, "#{self.class}#handle_missing_vault not implemented"
  end

  def handle_foreign_vault
    raise NotImplementedError, "#{self.class}#handle_foreign_vault not implemented"
  end
end
