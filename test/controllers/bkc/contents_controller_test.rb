require "test_helper"

class Bkc::ContentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      email: "owner@example.com",
      display_name: "Owner",
      role: "owner",
      status: "active",
      trust_level: 0,
      can_create_vault: true
    )
    @vault = @owner.create_vault!(display_name: "Owner Vault")
  end

  test "lists vault contents" do
    @vault.contents.create!(title: "First", body: "Body", required_level: 0)

    get bkc_contents_path, headers: { "X-Test-User-Id" => @owner.id }

    assert_response :success
    assert_select "td", "First"
  end

  test "creates new content" do
    assert_difference "Content.count", 1 do
      post bkc_contents_path,
           params: { content: { title: "New", body: "Body", required_level: 1, format: "markdown" } },
           headers: { "X-Test-User-Id" => @owner.id }
    end

    assert_redirected_to bkc_contents_path
    assert_equal "New", @vault.contents.last.title
  end

  test "rejects invalid content with errors" do
    assert_no_difference "Content.count" do
      post bkc_contents_path,
           params: { content: { title: "", body: "", required_level: 0 } },
           headers: { "X-Test-User-Id" => @owner.id }
    end

    assert_response :unprocessable_entity
  end

  test "edits existing content" do
    content = @vault.contents.create!(title: "Old", body: "Body", required_level: 0)

    get edit_bkc_content_path(content), headers: { "X-Test-User-Id" => @owner.id }

    assert_response :success
    assert_select "input[value=?]", "Old"
  end

  test "updates content" do
    content = @vault.contents.create!(title: "Old", body: "Old body", required_level: 0)

    patch bkc_content_path(content),
          params: { content: { title: "New" } },
          headers: { "X-Test-User-Id" => @owner.id }

    assert_redirected_to bkc_contents_path
    assert_equal "New", content.reload.title
  end

  test "deletes content" do
    content = @vault.contents.create!(title: "Doomed", body: "Body", required_level: 0)

    assert_difference "Content.count", -1 do
      delete bkc_content_path(content), headers: { "X-Test-User-Id" => @owner.id }
    end

    assert_redirected_to bkc_contents_path
  end

  test "cannot access other vault's content" do
    other_owner = User.create!(email: "other@example.com", display_name: "Other", role: "owner")
    other_vault = other_owner.create_vault!(display_name: "Other Vault")
    foreign = other_vault.contents.create!(title: "Foreign", body: "Body", required_level: 0)

    get edit_bkc_content_path(foreign), headers: { "X-Test-User-Id" => @owner.id }

    assert_response :not_found
  end
end
