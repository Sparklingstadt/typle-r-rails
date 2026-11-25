require "test_helper"

class Ui::ClassesTest < ActiveSupport::TestCase
  include Ui::Classes

  test "cn leaves out nil, false and empty strings" do
    assert_equal "a b", cn("a", false, nil, "", "b")
    assert_equal "a c", cn("a", false && "b", nil, "c")
    assert_equal "a b", cn(["a", [false, "b"]])
  end
end
