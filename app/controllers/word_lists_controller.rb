require "csv"

class WordListsController < ApplicationController
  before_action :set_pack, only: %i[new create]
  before_action :set_list, only: %i[edit update destroy export weak_review copy]
  before_action :require_editable, only: %i[new create edit update copy]

  def new
    @list = (@pack || current_user.packs.new).word_lists.new
  end

  # From a pack, or from /create, where the pack is chosen in the form: one of the user's own packs, or a new pack
  # named after the list (typle-r's "新しいパック（リスト名で作成）").
  def create
    pack = @pack || own_packs.find_by(id: params.dig(:word_list, :pack_id).presence) || current_user.packs.new
    @list = pack.word_lists.new(list_params.merge(user: current_user))
    pack.name = @list.name if pack.new_record?
    if pack.new_record? ? save_with_new_pack(pack) : @list.save
      redirect_to packs_path(pack: pack.id), notice: helpers.tt("wordLists.page.created", name: @list.name)
    else
      @pack ||= nil
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @own_packs = own_packs
  end

  # typle-r's editor also moves the list to another of the user's packs, or to a new pack named after it; a pack left
  # without lists goes.
  def update
    @own_packs = own_packs
    left = @list.pack
    WordList.transaction do
      @list.assign_attributes(list_params)
      if params[:word_list]&.key?(:pack_id)
        target = own_packs.find_by(id: params.dig(:word_list, :pack_id).presence) || current_user.packs.new(name: @list.name)
        if target != left
          target.save! if target.new_record?
          @list.pack = target
          @list.position = (target.word_lists.maximum(:position) || 0) + 1
        end
      end
      @list.save!
      left.destroy! if left != @list.pack && left.word_lists.reload.empty?
    end
    redirect_to packs_path(open: @list.pack_id, list: @list.id), notice: helpers.tt("wordLists.page.updated", name: @list.name)
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @list.destroy
    redirect_to packs_path(open: @list.pack_id), notice: helpers.tt("wordLists.page.deleted", name: @list.name), status: :see_other
  end

  def export
    # typle-r's encodeWordCsv: a header, every cell quoted, CRLF; input_type only when a word has one.
    typed = @list.words.any?(&:input_type)
    cell = ->(value) { %("#{value.to_s.gsub('"', '""')}") }
    lines = [["input", "display", "annotation", *("input_type" if typed)].join(",")]
    lines += @list.words.map { |w| [w.input, w.display, w.annotation, *(w.input_type.to_s if typed)].map(&cell).join(",") }
    send_data "\uFEFF" + lines.join("\r\n") + "\r\n", filename: "#{@list.name}.csv", type: "text/csv; charset=utf-8"
  end

  # typle-r's duplicateList: a copy at the end of the same pack, without records.
  def copy
    copy = begin
      PackFile.copy_list(@list, ->(n) { helpers.copy_suffix(n) })
    rescue ActiveRecord::RecordInvalid => error
      return redirect_to packs_path(open: @list.pack_id), alert: error.record.errors.full_messages.to_sentence
    end
    redirect_to packs_path(open: copy.pack_id, list: copy.id), notice: helpers.tt("wordLists.page.created", name: copy.name)
  end

  # Called by the practice screen when a practice of the list's weak words alone has finished.
  def weak_review
    missed = Array(params[:missed]).map { |item| { "word" => item[:word].to_s, "count" => item[:count].to_i } }
    @list.update!(weak_reviewed_at: Time.current, weak_review_missed: missed)
    head :no_content
  end

  private
    def set_pack
      @pack = current_user.packs.find(params[:pack_id]) if params[:pack_id]
      @own_packs = own_packs unless @pack
    end

    def own_packs = current_user.packs.where(catalog_id: nil)

    def save_with_new_pack(pack)
      Pack.transaction do
        pack.save!
        @list.save!
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def set_list
      @list = current_user.word_lists.find(params[:id])
      @pack = @list.pack
    end

    def require_editable
      redirect_to packs_path(pack: @pack.id), alert: helpers.tt("errors.packFollowed") if @pack && !@pack.editable?
    end

    def list_params
      permitted = params.expect(word_list: [:name, :level, :words_text, :writing_language, words_rows: [[:display, :input, :annotation, :input_type]]])
      permitted.delete(:words_text) if permitted.key?(:words_rows)
      permitted
    end
end
