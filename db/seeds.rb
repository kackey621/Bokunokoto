# Initial operator and sample users
admin = User.find_or_create_by!(email: "admin@bokunokoto.test") do |u|
  u.display_name = "Platform Admin"
  u.role = "admin"
  u.status = "active"
  u.trust_level = 9
end

owner = User.find_or_create_by!(email: "akira@bokunokoto.test") do |u|
  u.display_name = "Akira"
  u.role = "owner"
  u.status = "active"
  u.trust_level = 0
  u.can_create_vault = true
  u.bkc_access = true
end

# Initialize Akira's vault if not exists
unless owner.vault
  owner.create_vault!(
    display_name: "Akira's Disclosure Space",
    bio: "This is a private space for my personal disclosures."
  )
end

# Sample viewers
viewer1 = User.find_or_create_by!(email: "viewer1@bokunokoto.test") do |u|
  u.display_name = "Trusted Friend"
  u.role = "viewer"
end

viewer2 = User.find_or_create_by!(email: "viewer2@bokunokoto.test") do |u|
  u.display_name = "New Contact"
  u.role = "viewer"
end

# Grant permissions for Akira's vault
if owner.vault
  Permission.find_or_create_by!(vault: owner.vault, user: viewer1) do |p|
    p.granted_level = 5
    p.relationship_context = "Close friend from college"
  end

  Permission.find_or_create_by!(vault: owner.vault, user: viewer2) do |p|
    p.granted_level = 1
    p.relationship_context = "Met at the community event"
  end

  # Sample content
  Content.find_or_create_by!(vault: owner.vault, title: "Welcome") do |c|
    c.body = "# Welcome to my vault\n\nI will share more as we build trust."
    c.required_level = 0
  end

  Content.find_or_create_by!(vault: owner.vault, title: "My Health Condition") do |c|
    c.body = "I was diagnosed with chronic fatigue syndrome in 2024..."
    c.required_level = 5
  end
end
