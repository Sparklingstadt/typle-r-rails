require "test_helper"

# typle-r's sid:link (tests/sidLinks.test.cjs): linking a Sparklingstadt ID to the account of another login.
class SidLinkTest < ActiveSupport::TestCase
  setup do
    @account = users(:two)
    OfficialCatalog.follow(@account, "pack-vim-beginner")
  end

  test "reads a sub with or without sid:" do
    assert_equal "abc123", SidLink.parse_sub("abc123")
    assert_equal "abc123", SidLink.parse_sub("sid:abc123")
    assert_nil SidLink.parse_sub("ABC")
    assert_nil SidLink.parse_sub("sid:")
    assert_nil SidLink.parse_sub(nil)
  end

  test "links an ID to an account by its login ID or github:<id>, and its login then opens that account" do
    assert_equal :linked, SidLink.link("abc123", "TWO")
    assert_equal "abc123", @account.reload.sid_sub
    assert_equal @account, User.for_sid!("abc123", name: "x")
    @account.update!(sid_sub: nil)
    assert_equal :linked, SidLink.link("abc123", "github:2")
  end

  test "the ID's own account, with nothing saved, gives way" do
    own = User.for_sid!("abc123", name: "x")
    own.sessions.create!
    assert_equal :linked, SidLink.link("abc123", "two")
    assert_not User.exists?(own.id)
    assert_equal @account, User.for_sid!("abc123", name: "x")
  end

  test "refuses an ID that is linked already" do
    SidLink.link("abc123", "two")
    other = User.create!(login_id: "other", github_uid: "3")
    OfficialCatalog.follow(other, "pack-vim-beginner")
    assert_equal :sub_linked, SidLink.link("abc123", "other")
    assert_equal :sub_linked, SidLink.link("abc123", "two")
  end

  test "refuses an account that has another ID" do
    SidLink.link("abc123", "two")
    assert_equal :account_linked, SidLink.link("def456", "two")
    assert_equal "abc123", @account.reload.sid_sub
  end

  test "refuses an account that is not one of another login, or is not there" do
    assert_equal :account_invalid, SidLink.link("abc123", "nobody")
    assert_equal :account_invalid, SidLink.link("abc123", "github:999")
    assert_equal :account_invalid, SidLink.link("abc123", "")
  end

  test "refuses an account with nothing saved, a likely typo" do
    User.create!(login_id: "empty", github_uid: "4")
    assert_equal :account_empty, SidLink.link("abc123", "empty")
    assert_nil User.find_by(login_id: "empty").sid_sub
  end

  test "refuses an ID whose own account has saved data, which the link would leave behind" do
    own = User.for_sid!("abc123", name: "x")
    OfficialCatalog.follow(own, "pack-vim-beginner")
    assert_equal :sid_has_data, SidLink.link("abc123", "two")
    assert_equal own, User.for_sid!("abc123", name: "x")
    assert_nil @account.reload.sid_sub
  end

  test "the task says what it did and to which database, and fails on a refusal" do
    require "rake"
    Rails.application.load_tasks unless Rake::Task.task_defined?("sid:link")
    out, = capture_io { Rake::Task["sid:link"].execute(Rake::TaskArguments.new(%i[sub account], %w[sid:abc123 two])) }
    assert_match(/\Aひも付けました。（sid:abc123 → two、DB: sqlite3 \S+）\n\z/, out)
    error = assert_raises(SystemExit) do
      capture_io { Rake::Task["sid:link"].execute(Rake::TaskArguments.new(%i[sub account], %w[abc123 two])) }
    end
    assert_equal 1, error.status
    assert_raises(SystemExit) { capture_io { Rake::Task["sid:link"].execute(Rake::TaskArguments.new(%i[sub account], %w[BAD two])) } }
  end
end
