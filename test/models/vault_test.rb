require "test_helper"

class VaultTest < ActiveSupport::TestCase
  test "vault belongs to owner" do
    owner = User.create!(email: "owner@example.com", display_name: "Owner", role: "owner")
    vault = owner.owned_vaults.create!(display_name: "Vault")

    assert_equal owner, vault.owner
    assert_equal owner, vault.user
  end

  test "active and archived scopes" do
    owner = User.create!(email: "o@example.com", display_name: "O", role: "owner")
    active_v = owner.owned_vaults.create!(display_name: "Active")
    archived_v = owner.owned_vaults.create!(display_name: "Archived", archived_at: Time.current)

    assert_includes Vault.active, active_v
    assert_not_includes Vault.active, archived_v
    assert_includes Vault.archived, archived_v
    assert_not_includes Vault.archived, active_v
  end

  test "archived? reflects archived_at" do
    owner = User.create!(email: "p@example.com", display_name: "P", role: "owner")
    vault = owner.owned_vaults.create!(display_name: "V")

    refute vault.archived?
    vault.update!(archived_at: Time.current)
    assert vault.archived?
  end

  test "kind defaults to personal" do
    owner = User.create!(email: "q@example.com", display_name: "Q", role: "owner")
    vault = owner.owned_vaults.create!(display_name: "V")
    assert_equal "personal", vault.kind
  end
end
