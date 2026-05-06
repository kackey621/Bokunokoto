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

    vault1 = owner1.create_vault!(display_name: "Vault 1")
    vault2 = owner2.create_vault!(display_name: "Vault 2")

    viewer.permissions.create!(vault: vault1, granted_level: 3)
    viewer.permissions.create!(vault: vault2, granted_level: 5)

    assert_equal 3, viewer.trust_level_for(vault1)
    assert_equal 5, viewer.trust_level_for(vault2)
    assert_equal 0, viewer.trust_level_for(Vault.new) # No permission
    assert_equal 9, owner1.trust_level_for(vault1) # Owner access
  end
end
