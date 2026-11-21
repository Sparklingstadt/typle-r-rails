# 単語一覧 (typle-r's WordsView): choose a list on the left and see its words. ?list=<id> keeps the choice in the URL;
# without it the first list is shown, as on the practice screen.
class WordsController < ApplicationController
  def index
    @lists = current_user.word_lists.includes(:pack, :words, :practice_records).order("packs.position", :position).references(:pack).to_a
    @requested = params[:list].presence
    @list = @lists.find { |list| list.id.to_s == @requested } || @lists.first
  end
end
