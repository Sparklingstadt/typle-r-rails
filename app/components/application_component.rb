# The base of the app's components: typle-r's class strings and cn() (Ui::Classes), and its lucide icons.
class ApplicationComponent < ViewComponent::Base
  include Ui::Classes

  delegate :icon, to: :helpers

  private

  # `class:` as a keyword: the components take it the way the helpers (and typle-r's className) do.
  def class_option(binding) = binding.local_variable_get(:class)
end
