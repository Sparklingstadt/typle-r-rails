require "test_helper"

class Guide::ColorLegendComponentTest < ViewComponent::TestCase
  test "each example shows its letters in their states, with nothing between them" do
    render_inline(Guide::ColorLegendComponent.new)

    assert_selector "figure", count: GuideDesignHelper::GUIDE_LEGEND.size
    letters = page.first("figure p.whitespace-pre-wrap").native
    assert letters.children.all?(&:element?), "no text (no whitespace) between the letters: the paragraph keeps whitespace"
    assert_selector "span[data-state=done]"
    assert_selector "span[data-state=current]"
  end
end
