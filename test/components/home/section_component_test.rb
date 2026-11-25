require "test_helper"

class Home::SectionComponentTest < ViewComponent::TestCase
  test "a section is labelled by its heading" do
    render_inline(Home::SectionComponent.new(id: "week-heading", title: "今週", description: "月曜から")) { "中身" }

    assert_selector "section[aria-labelledby=week-heading] h2#week-heading", text: "今週"
    assert_selector "section p", text: "月曜から"
    assert_text "中身"
  end
end
