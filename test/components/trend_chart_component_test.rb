require "test_helper"

class TrendChartComponentTest < ViewComponent::TestCase
  def chart(values)
    points = values.each_with_index.map { |value, index| TrendChartComponent::Point.new(value:, value_text: "#{value}s", date_text: "11/#{index + 1}") }
    TrendChartComponent.new(label: "速さ", points:, scale: Dashboard.speed_scale(values), dates: ["11/1", "11/#{values.size}"], messages: "design.records.chart")
  end

  test "the runs are drawn from left to right, the latest marked, with a table for screen readers" do
    render_inline(chart([4.0, 3.0, 5.0]))

    slider = page.find("[role=slider][data-controller=trend-chart]")
    assert_equal "3", slider["aria-valuemax"]
    assert_equal "11/3 5.0s", slider["aria-valuetext"]
    points = JSON.parse(slider["data-trend-chart-points-value"])
    assert_equal [0.0, 50.0, 100.0], points.map { _1["x"] }
    assert_operator points[1]["y"], :>, points[2]["y"], "a smaller value is lower"
    assert_selector "span[data-trend-chart-target=dot][style*='left: 100.0%']", visible: :all
    assert_selector "table.sr-only caption", text: "速さ", visible: :all
    assert_selector "table.sr-only tbody tr", count: 3, visible: :all
    assert_selector "figcaption span", text: "11/1", visible: :all
  end

  test "one run is no chart" do
    render_inline(chart([4.0]))

    assert_no_selector "figure"
  end
end
