ENV["RAILS_ENV"] ||= "test"
# Both logins are on in the tests (the sign-in page reads these on each request; the OmniAuth strategies are set up at
# boot). The Sparklingstadt ID server is answered by WebMock (test/test_helpers/sid_server.rb).
ENV["SID_ISSUER"] = "https://id.example.test"
ENV["SID_CLIENT_ID"] = "typle-r"
ENV["SID_CLIENT_SECRET"] = "test-secret"
ENV["GITHUB_CLIENT_ID"] = "test-github"
ENV["GITHUB_CLIENT_SECRET"] = "test-github-secret"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/sid_server"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
