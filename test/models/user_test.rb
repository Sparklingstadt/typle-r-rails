require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes the login id" do
    assert_equal "alice", User.new(login_id: "  Alice ").login_id
  end

  test "rejects a taken or malformed id, and a sub not of its form" do
    assert_not User.new(login_id: "two").valid?
    assert_not User.new(login_id: "has space").valid?
    assert_not User.new(login_id: "new.one").valid?, "typle-r's IDs have no dots"
    assert User.new(login_id: "new_one-2").valid?
    assert User.new(sid_sub: "abc123").valid?, "a Sparklingstadt ID account has no login ID"
    assert_not User.new(sid_sub: "ABC").valid?
    assert_not User.new(sid_sub: "one1").valid?, "one account per sub"
  end

  test "an ID's own account opens by its sub, and is made on its first login" do
    assert_equal users(:one), User.for_sid!("one1", name: "One")
    assert_difference(-> { User.count }) { User.for_sid!("new1", name: "New") }
    user = User.find_by!(sid_sub: "new1")
    assert_equal [:sid, "New"], [user.login_kind, user.display_name]
    assert_no_difference(-> { User.count }) { User.for_sid!("new1", name: "Renamed") }
    assert_equal "Renamed", user.reload.name, "an ID's own account keeps the ID's name"
  end

  test "a linked account opens as itself and keeps its name" do
    users(:two).update!(sid_sub: "linked1")
    assert_equal users(:two), User.for_sid!("linked1", name: "Someone")
    assert_equal [:github, "two"], [users(:two).reload.login_kind, users(:two).display_name]
  end
end
