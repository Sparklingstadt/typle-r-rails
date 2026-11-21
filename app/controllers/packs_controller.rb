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
    # typle-r reads files up to 1 MiB.
    return redirect_to packs_path, alert: helpers.tt("errors.importTooLarge") if file.size > 1.megabyte
    name = File.basename(file.original_filename.to_s, ".*").presence || t(".default_name")
    text = file.read.force_encoding("UTF-8").delete_prefix("﻿")
    if file.original_filename.to_s.end_with?(".json") || text.lstrip.start_with?("{")
      pack = PackFile.import(current_user, text)
      return redirect_to packs_path(pack: pack.id), notice: tt_message("wordLists.page.created", name: pack.name)
    end
    pack = current_user.packs.new(name:)
    list = pack.word_lists.new(user: current_user, name:)
    # A file with typle-r's header (input, display, annotation, input_type in any order) is read by its columns;
    # without one, each line is display, input, annotation.
    rows = CSV.parse(text) rescue nil
    header = rows&.first&.map { |cell| cell.to_s.strip.downcase.sub(/\Aanotation\z/, "annotation") }
    if header&.include?("input") && header.include?("display")
      list.words_rows = rows.drop(1).reject { |cells| cells.compact_blank.empty? }.map { |cells| header.zip(cells).to_h.slice("display", "input", "annotation", "input_type") }
    else
      list.words_text = text
    end
    Pack.transaction do
      pack.save!
      list.save!
    end
    redirect_to packs_path(pack: pack.id), notice: tt_message("wordLists.page.created", name: pack.name)
  rescue PackFile::Unreadable
    redirect_to packs_path, alert: helpers.tt("errors.packFileUnreadable")
  rescue ActiveRecord::RecordInvalid => error
    redirect_to packs_path, alert: t(".failed", reason: error.record.errors.full_messages.to_sentence)
  rescue ArgumentError
    redirect_to packs_path, alert: t(".failed", reason: t(".not_utf8"))
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
