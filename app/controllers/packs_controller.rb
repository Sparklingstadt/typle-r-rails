require "csv"

class PacksController < ApplicationController
  before_action :set_pack, only: %i[show edit update destroy export copy]
  before_action :require_editable, only: %i[edit update]

  def index
    @order = params[:order].in?(%w[practiced name words]) ? params[:order] : "added"
    packs = current_user.packs.includes(word_lists: %i[words practice_records]).to_a
    # typle-r's sortPacks: the newest first unless another order is chosen.
    @packs = case @order
    when "name" then packs.sort_by { |pack| [Collation.key(pack.name), -pack.position] }
    when "words" then packs.sort_by { |pack| [-pack.word_count, -pack.position] }
    when "practiced" then packs.sort_by { |pack| [-(pack.last_practiced_at&.to_f || -Float::INFINITY), -pack.position] }
    else packs.sort_by { |pack| -pack.position }
    end
    # `?pack=<id>` (after a save, as typle-r's /edit?pack=) opens that pack and points at its row; `?open=<id>` opens it
    # without pointing (after a list is saved or deleted, the list's row, `?list=<id>`, is pointed at instead).
    @pointed_pack_id = params[:pack].presence&.to_i
    @open_pack_id = params[:open].presence&.to_i
    @pointed_list_id = params[:list].presence&.to_i
  end

  # typle-r has no screen of its own for a pack: its lists open in the word packs list.
  def show
    flash.keep
    redirect_to packs_path(pack: @pack.id)
  end

  # typle-r's パックを作成: a pack is made of lists the user already has (their own, not followed ones).
  def new
    @pack = current_user.packs.new
    @choices = own_lists
  end

  def create
    @pack = current_user.packs.new(pack_params)
    @choices = own_lists
    chosen = @choices.select { |list| Array(params[:list_ids]).map(&:to_s).include?(list.id.to_s) }
    saved = Pack.transaction do
      next false unless @pack.save
      sources = chosen.map(&:pack).uniq
      chosen.each_with_index { |list, index| list.update_columns(pack_id: @pack.id, position: index + 1) }
      # A pack left without lists goes, as in typle-r.
      sources.each { |source| source.reload.destroy if source.word_lists.empty? }
      true
    end
    if saved
      redirect_to packs_path(pack: @pack.id), notice: tt_message("wordLists.packEditor.created", name: @pack.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  # typle-r's PackEditor: the pack's fields, and the order of its lists (list_ids[], top first).
  def update
    order = Array(params[:list_ids]).map(&:to_i)
    saved = Pack.transaction do
      next false unless @pack.update(pack_params)
      @pack.word_lists.each { |list| list.update_columns(position: order.index(list.id).to_i + 1) if order.include?(list.id) }
      true
    end
    if saved
      redirect_to packs_path(pack: @pack.id), notice: tt_message("wordLists.packEditor.updated", name: @pack.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pack.destroy
    redirect_to packs_path, notice: tt_message("wordLists.page.packDeleted", name: @pack.name), status: :see_other
  end

  # typle-r's パックを書き出す: the pack file (`<name>.typle-pack.json`), without records.
  def export
    send_data PackFile.encode(@pack), filename: "#{@pack.name}.typle-pack.json", type: "application/json; charset=utf-8"
  end

  # typle-r's 複製: a copy of the pack and its lists, without records, after the user's other packs.
  def copy
    copy = begin
      PackFile.copy(@pack, copy_suffix)
    rescue ActiveRecord::RecordInvalid => error
      return redirect_to packs_path, alert: error.record.errors.full_messages.to_sentence
    end
    redirect_to packs_path(pack: copy.id), notice: tt_message("wordLists.page.created", name: copy.name)
  end

  # ファイルから読み込む: typle-r's pack file makes a new pack. A CSV or TSV file (display, input, annotation per row,
  # or typle-r's header) is read too, as one list.
  def import
    file = params[:file]
    return redirect_to packs_path, alert: t(".no_file") unless file.respond_to?(:read)
    pack = PackImport.call(current_user, file, default_name: t(".default_name"))
    redirect_to packs_path(pack: pack.id), notice: tt_message("wordLists.page.created", name: pack.name)
  rescue PackImport::TooLarge
    redirect_to packs_path, alert: helpers.tt("errors.importTooLarge")
  rescue PackImport::NotUtf8
    redirect_to packs_path, alert: t(".failed", reason: t(".not_utf8"))
  rescue PackFile::Unreadable
    redirect_to packs_path, alert: helpers.tt("errors.packFileUnreadable")
  rescue ActiveRecord::RecordInvalid => error
    redirect_to packs_path, alert: t(".failed", reason: error.record.errors.full_messages.to_sentence)
  end

  private
    def own_lists = current_user.word_lists.joins(:pack).where(packs: { catalog_id: nil }).includes(:pack, :words).order("packs.position", :position).to_a

    # The tags come as tags[] (the chips of LabelFields); none chosen sends a blank one so that clearing them saves.
    def pack_params
      permitted = params.expect(pack: [:name, :description, :category, tags: []])
      permitted[:tags] = Array(permitted[:tags]).compact_blank if permitted.key?(:tags)
      permitted
    end

    def tt_message(key, **values) = helpers.tt(key, **values)

    def copy_suffix = ->(n) { helpers.copy_suffix(n) }

    def set_pack
      @pack = current_user.packs.find(params[:id])
    end

    def require_editable
      redirect_to packs_path(pack: @pack.id), alert: helpers.tt("errors.packFollowed") unless @pack.editable?
    end
end
