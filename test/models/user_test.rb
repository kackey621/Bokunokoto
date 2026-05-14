require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "validates role status and trust level" do
    user = User.new(email: "Owner@Example.test", display_name: "Owner", role: "admin", status: "active", trust_level: 9)

    assert user.valid?
    assert_equal "owner@example.test", user.email
  end

  test "returns correct trust level for different vaults" do
    owner1 = User.create!(email: "owner1@example.com", display_name: "Owner 1", role: "owner")
    owner2 = User.create!(email: "owner2@example.com", display_name: "Owner 2", role: "owner")
    viewer = User.create!(email: "viewer@example.com", display_name: "Viewer", role: "viewer")

    vault1 = owner1.owned_vaults.create!(display_name: "Vault 1")
    vault2 = owner2.owned_vaults.create!(display_name: "Vault 2")

    viewer.permissions.create!(vault: vault1, granted_level: 3)
    viewer.permissions.create!(vault: vault2, granted_level: 5)

    assert_equal 3, viewer.trust_level_for(vault1)
    assert_equal 5, viewer.trust_level_for(vault2)
    assert_equal 0, viewer.trust_level_for(Vault.new)
    assert_equal 9, owner1.trust_level_for(vault1)
  end

  test "suspended or pending permission contributes zero trust level" do
    owner = User.create!(email: "owner@example.com", display_name: "Owner", role: "owner")
    vault = owner.owned_vaults.create!(display_name: "Vault")
    viewer = User.create!(email: "viewer2@example.com", display_name: "Viewer", role: "viewer")

    viewer.permissions.create!(vault: vault, granted_level: 7, status: "suspended")
    assert_equal 0, viewer.trust_level_for(vault)

    viewer.permissions.find_by(vault: vault).update!(status: "pending")
    assert_equal 0, viewer.trust_level_for(vault)
  end

  test "owns? is true for the vault's user and false for others" do
    owner = User.create!(email: "a@example.com", display_name: "A", role: "owner")
    other = User.create!(email: "b@example.com", display_name: "B", role: "viewer")
    vault = owner.owned_vaults.create!(display_name: "V")

    assert owner.owns?(vault)
    refute other.owns?(vault)
    refute owner.owns?(nil)
  end

  test "default_vault returns default_vault_id vault when set, falls back to first" do
    owner = User.create!(email: "c@example.com", display_name: "C", role: "owner")
    v1 = owner.owned_vaults.create!(display_name: "V1")
    v2 = owner.owned_vaults.create!(display_name: "V2")

    assert_equal v1, owner.default_vault

    owner.update!(default_vault_id: v2.id)
    assert_equal v2, owner.reload.default_vault
  end

  test "default_vault returns nil when user owns no vaults" do
    user = User.create!(email: "d@example.com", display_name: "D", role: "viewer")
    assert_nil user.default_vault
  end

  test "user can own multiple vaults" do
    owner = User.create!(email: "e@example.com", display_name: "E", role: "owner")
    owner.owned_vaults.create!(display_name: "V1")
    owner.owned_vaults.create!(display_name: "V2")
    owner.owned_vaults.create!(display_name: "V3")

    assert_equal 3, owner.owned_vaults.count
  end
end
