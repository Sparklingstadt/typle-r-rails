# /play: typing practice of one of the user's lists (?list=<id>) or of an official list (?official=<id>, also for guests).
# ?mode=recall hides the words and shows only their annotation. ?review=weak practises the list's weak words alone.
class PracticeController < ApplicationController
  # The packs offered when there is nothing to practise yet, as in typle-r's src/lib/packs/starters.ts.
  STARTER_CATALOG_IDS = %w[pack-english-basic-words pack-0b27f311-38aa-40aa-9c29-ea17e374e1fe pack-chinese-hsk5-words-1].freeze

  def show
    @mode = params[:mode].in?(%w[recall writing]) ? params[:mode] : nil
    if params[:official].present?
      @pack, official = OfficialCatalog.find_list(params[:official]) || raise(ActiveRecord::RecordNotFound)
      @list_name = official.name == @pack.name ? official.name : "#{@pack.name} › #{official.level.presence || official.name}"
      @words = official.words.map { |w| w.slice(:display, :input, :annotation, :input_type) }
      @writing_language = official.writing_language
      @mode = nil if @mode == "writing" && !@writing_language
    else
      @lists = current_user.word_lists.includes(:pack, :words, :practice_records).order("packs.position", :position).references(:pack).to_a
      @list = params[:list].present? ? current_user.word_lists.find(params[:list]) : default_list
      return render_starters unless @list
      @list_name = @list.full_name
      @words = @list.words.map(&:as_practice_json)
      @writing_language = @list.writing_language
      @weak = params[:review] == "weak"
      if @weak
        weak = Dashboard.weak_words(@list, @list.practice_records.recent.to_a).map(&:word)
        @words = @words.select { |w| weak.include?(w[:input]) }
        return redirect_to play_path(list: @list.id), alert: t(".no_weak_words") if @words.empty?
      end
      @mode = nil if @mode == "writing" && !@list.writing?
      @best = @list.best(@mode)
      # After a run is saved in place, the page is fetched again to refresh the best records with the new run marked.
      @highlight = @list.practice_records.find_by(id: params[:highlight]) if params[:highlight].present?
    end
    @device = DeviceChoice.new(cookies, current_user)
  end

  private
    def default_list
      return if params[:official].present?
      # typle-r's usePractice: the first list, in the order of the packs and their lists.
      @lists.find { |l| l.words.any? }
    end

    def render_starters
      @starters = STARTER_CATALOG_IDS.filter_map { |id| OfficialCatalog.find(id) }
      @starters = OfficialCatalog.packs.first(3) if @starters.empty?
      render :starters
    end
end
