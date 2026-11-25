# typle-r's ContinueCard: the list practised last, with its first words, its best and a button to practise it again.
class Home::ContinueComponent < ApplicationComponent
  SAMPLES = 3

  delegate :home_t, :home_day, :practice_name, :format_accuracy, :link_button, :card, to: :helpers

  def initialize(dashboard:, now:)
    @dashboard = dashboard
    @list = dashboard.continue_list
    @now = now
  end

  def render? = @list.present?

  private

  attr_reader :list, :now

  def best = list.best

  def last_practiced = @dashboard.records.find { |record| record.word_list_id == list.id }.practiced_at

  def samples = list.words.first(SAMPLES)

  def rest = list.words.size - SAMPLES
end
