require "test_helper"

class Api::V1::HealthControllerTest < ActionDispatch::IntegrationTest
  test "returns api health" do
    get api_v1_health_path

    assert_response :success
    assert_equal "ok", response.parsed_body["status"]
  end
end
