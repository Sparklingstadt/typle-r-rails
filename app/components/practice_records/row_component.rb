# typle-r's RecordRow: one run in the history. With one list selected (`show_list` false) the device becomes the row's
# title; with a pack chosen (`in_pack`) the pack's name is left out. `best` marks the list's best run, whose deletion
# says what becomes the best after it.
class PracticeRecords::RowComponent < ApplicationComponent
  delegate :tt, :practice_name, :delete_confirm_data, :records_t, :records_accuracy, :records_clock, :records_day_heading,
           :records_device, :records_level_name, :records_mode_badge, :records_best_badge, :records_numeric_date, :records_time,
           :records_time_text, :records_unit_space, to: :helpers

  def initialize(record:, show_list:, in_pack:, best:)
    @record = record
    @list = record.word_list
    @show_list = show_list
    @in_pack = in_pack
    @best = best
  end

  private

  attr_reader :record, :list

  def best? = @best

  def show_list? = @show_list

  def low_accuracy? = record.accuracy < RecordsDesignHelper::LOW_ACCURACY

  def time = @time ||= records_clock(record.practiced_at)

  def device = @device ||= records_device(record)

  def title
    return device unless show_list?
    @in_pack ? records_level_name(list) : list.full_name
  end

  # typle-r's RecordDeleteDetails: when the run is the list's best, the run that becomes the best (one of the same mode,
  # over the list's words as they are now if there is one), or that none is left.
  def best_note
    return unless best?
    rest = list.practice_records.select { |other| other.mode == record.mode && other != record }
    same = rest.select { |other| other.word_count == list.words.size }
    following = PracticeRecord.ranked(same.any? ? same : rest).first
    return records_t("history.delete.best_last") unless following
    records_t("history.delete.best_next", time: records_time_text(following.seconds), accuracy: records_accuracy(following.accuracy))
  end

  def confirm_data(details)
    delete_confirm_data(title: records_t("history.delete.title"), description: records_t("history.delete.description", name: list.full_name), details:)
  end
end
