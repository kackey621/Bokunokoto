ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module ConsoleAuthTestHelper
  def as_platform_admin
    @platform_admin ||= User.create!(
      email: "platform-admin-#{SecureRandom.hex(4)}@example.test",
      display_name: "Test Platform Admin",
      role: "admin",
      status: "active",
      trust_level: 9
    )
    { "X-Test-User-Id" => @platform_admin.id.to_s }
  end
end

class ActionDispatch::IntegrationTest
  include ConsoleAuthTestHelper
end
