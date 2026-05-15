require "test_helper"

class Bkc::ForensicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      email: "fowner@example.com",
      display_name: "Forensics Owner",
      role: "owner",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    @vault = @owner.create_vault!(display_name: "Forensics Vault")

    @viewer = User.create!(
      email: "fviewer@example.com",
      display_name: "Viewer",
      role: "viewer",
      status: "active"
    )
    Permission.create!(vault: @vault, user: @viewer, granted_level: 3)
  end

  test "GET index shows audit log feed" do
    AuditLog.create!(vault: @vault, user: @viewer, action: "view", occurred_at: 1.hour.ago)

    get bkc_forensics_path, headers: { "X-Test-User-Id" => @owner.id }

    assert_response :success
    assert_select "h1", "Forensic Monitoring"
  end

  test "GET timeline scopes audit logs to a single user" do
    AuditLog.create!(vault: @vault, user: @viewer, action: "view", occurred_at: 2.hours.ago)
    AuditLog.create!(vault: @vault, user: @viewer, action: "handshake", occurred_at: 1.hour.ago)
    AuditLog.create!(vault: @vault, user: @owner, action: "view", occurred_at: 30.minutes.ago)

    get bkc_forensics_user_timeline_path(user_id: @viewer.id), headers: { "X-Test-User-Id" => @owner.id }

    assert_response :success
    assert_select "h1", text: /Activity Timeline.*Viewer/
    assert_select ".timeline-action", text: /Handshake/
    assert_select ".timeline-action", text: /View/
    assert_select ".timeline-item", count: 2
  end

  test "GET timeline filters by date range" do
    AuditLog.create!(vault: @vault, user: @viewer, action: "view", occurred_at: 60.days.ago)
    AuditLog.create!(vault: @vault, user: @viewer, action: "view", occurred_at: 1.day.ago)

    get bkc_forensics_user_timeline_path(user_id: @viewer.id, start_date: 7.days.ago.to_date.to_s, end_date: Date.current.to_s),
        headers: { "X-Test-User-Id" => @owner.id }

    assert_response :success
    assert_select ".timeline-item", count: 1
  end

  test "GET timeline redirects when user not found" do
    get bkc_forensics_user_timeline_path(user_id: 999_999), headers: { "X-Test-User-Id" => @owner.id }

    assert_redirected_to bkc_forensics_path
    assert_equal "User not found.", flash[:alert]
  end

  test "GET timeline redirects when caller has no vault" do
    no_vault = User.create!(email: "novault@x.com", display_name: "No Vault", role: "viewer", status: "active")

    get bkc_forensics_user_timeline_path(user_id: @viewer.id), headers: { "X-Test-User-Id" => no_vault.id }

    assert_redirected_to bkc_dashboard_path
  end

  test "index paginates face snapshots at FACE_ARCHIVE_PER_PAGE" do
    per_page = Bkc::ForensicsController::FACE_ARCHIVE_PER_PAGE
    total = per_page + 6

    total.times do |i|
      AuditLog.create!(
        vault: @vault,
        user: @viewer,
        action: "view",
        face_snapshot_url: "https://example.test/face_#{i}.jpg",
        occurred_at: i.minutes.ago
      )
    end

    get bkc_forensics_path, headers: { "X-Test-User-Id" => @owner.id }
    assert_response :success
    assert_select "#face-archive-grid .face-card", count: per_page

    get bkc_forensics_path(page: 2), headers: { "X-Test-User-Id" => @owner.id }
    assert_response :success
    assert_select "#face-archive-grid .face-card", count: total - per_page
  end
end
