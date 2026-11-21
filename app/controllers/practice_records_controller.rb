class PracticeRecordsController < ApplicationController
  PAGE_SIZE = 50

  # 練習記録: every run by day, narrowed by pack, list and device (?pack= ?list= ?device=), PAGE_SIZE at a time (?shown=).
  def index
    @lists = current_user.word_lists.includes(:pack, :words, :practice_records).to_a
    @packs = current_user.packs.to_a
    @all = @lists.flat_map { |list| list.practice_records.to_a }.sort_by { |record| [-record.practiced_at.to_f, -record.id] }
    # The badge means "best of its own mode", as on every other screen.
    @bests = @lists.flat_map { |list| PracticeRecord::MODES.filter_map { |mode| list.best(mode) } }.to_set
    @pack = @packs.find { |pack| pack.id.to_s == params[:pack] }
    @list = @lists.find { |list| list.id.to_s == params[:list] && (!@pack || list.pack_id == @pack.id) }
    @device_options = DeviceOptions.new(current_user, @all)
    @device = @device_options.option_for(params[:device])&.value
    @records = @all.select { |record|
      (!@pack || record.word_list.pack_id == @pack.id) && (!@list || record.word_list_id == @list.id) && ListRanking.matches_device?(record, @device)
    }
    @shown = [params[:shown].to_i, PAGE_SIZE].max
  end

  def show
    @record = current_user.practice_records.find(params[:id])
    @list = @record.word_list
    @comparison = @record.comparison
  end

  # Saves a finished run, sent as JSON by the practice screen; answers with the result page's URL.
  def create
    list = current_user.word_lists.find(params[:word_list_id])
    record = list.practice_records.new(
      user: current_user,
      time_ms: params[:time_ms].to_i,
      mistakes: params[:mistakes].to_i,
      accuracy: params[:accuracy].to_f,
      word_count: list.words.size,
      mode: params[:mode].presence,
      missed: Array(params[:missed]).map { |item| { "word" => item[:word].to_s, "count" => item[:count].to_i } },
      **DeviceChoice.new(cookies, current_user).snapshot
    )
    if record.save
      render json: { id: record.id, url: practice_record_path(record), comparison: comparison_json(record) }, status: :created
    else
      render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    record = current_user.practice_records.find(params[:id])
    record.destroy
    # typle-r's records.delete.done, and the history stays where it was (its filters).
    notice = helpers.records_t("history.delete.done", name: record.word_list.full_name,
      date: helpers.records_t("extra.month_day", **helpers.records_date_parts(record.practiced_at)), time: helpers.records_clock(record.practiced_at))
    redirect_back_or_to practice_records_path, notice:, status: :see_other
  end

  private
    # How the run compares with the list's other runs, as typle-r's compareRun: the rank at this word count, and
    # best (with the difference to the previous best), behind (with that best), or the first record.
    def comparison_json(record)
      comparison = record.comparison
      case comparison[:kind]
      when :best then { rank: comparison[:rank], kind: "best", difference: comparison[:difference].round(2) }
      when :behind then { rank: comparison[:rank], kind: "behind", previous: { time: comparison[:best].seconds.round(2), accuracy: comparison[:best].accuracy.to_f } }
      else
        others = record.word_list.practice_records.any? { |other| other.id != record.id && other.mode == record.mode }
        { rank: comparison[:rank], kind: others ? "firstAtCount" : "firstForList" }
      end
    end
end
