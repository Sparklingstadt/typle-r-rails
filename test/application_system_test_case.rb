require "test_helper"
require "capybara/cuprite"

# The pages with their scripts, in headless Chrome (Cuprite). Chrome is found on the PATH, or at BROWSER_PATH.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, screen_size: [1280, 900], options: {
    headless: true, process_timeout: 30, timeout: 15, js_errors: true,
    browser_options: { "no-sandbox" => nil }
  }

  # The browser and Capybara's server talk over localhost; everything else stays blocked (WebMock).
  WebMock.disable_net_connect!(allow_localhost: true)
  # Icon buttons are named by their aria-label.
  Capybara.enable_aria_label = true

  # Types into the focused element as a person would: a key at a time, each with its input event.
  def type(text) = page.driver.browser.keyboard.type(text)

  def press(*keys) = page.driver.browser.keyboard.type(keys)

  # The words the practice screen holds (its words value), in order.
  def practice_words(controller = "practice")
    JSON.parse(find("[data-controller~=#{controller}]")["data-#{controller}-words-value"])
  end
end
