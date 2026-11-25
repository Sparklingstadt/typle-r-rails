# typle-r's DeleteDetails for a list: what deleting it removes (its words and records), and its CSV export to keep the
# words. Shown in the delete confirmation (ConfirmHelper#list_delete_confirm_data).
class WordLists::DeleteDetailsComponent < ApplicationComponent
  # The details go into a data attribute, as they are.
  strip_trailing_whitespace
  delegate :tt, :records_day, :button_classes, to: :helpers

  def initialize(list:, records:)
    @list = list
    @records = records
  end

  private

  attr_reader :list

  def contents
    last = @records.map(&:practiced_at).max
    [tt("wordLists.delete.wordCount", count: list.words.size),
     last ? tt("wordLists.delete.records", count: @records.size, day: records_day(last)) : tt("wordLists.delete.noRecords")].join(" · ")
  end
end
