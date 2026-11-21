require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes the login id" do
    assert_equal "alice", User.new(login_id: "  Alice ").login_id
  end

  test "rejects a short password and a taken or malformed id" do
    assert_not User.new(login_id: "new_one", password: "short").valid?
    assert_not User.new(login_id: "one", password: "password123").valid?
    assert_not User.new(login_id: "has space", password: "password123").valid?
    assert_not User.new(login_id: "new.one", password: "password123").valid?, "typle-r's IDs have no dots"
    assert User.new(login_id: "new_one-2", password: "password123").valid?
  end
end
