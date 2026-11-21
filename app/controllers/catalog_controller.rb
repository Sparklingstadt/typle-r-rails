class CatalogController < ApplicationController
  allow_unauthenticated_access only: %i[index show]

  def index
    @category = params[:category].presence
    @packs = OfficialCatalog.packs
    @packs = @packs.select { |p| p.category == @category } if @category
    @followed = current_user ? current_user.packs.where.not(catalog_id: nil).pluck(:catalog_id).to_set : Set.new
    if current_user && params[:category].blank?
      ids = current_user.interest_ids
      # Packs that fit the user's interests come first.
      @packs = @packs.partition { |pack| Interests.matches?(pack, ids) }.flatten
    end
  end

  def show
    @pack = OfficialCatalog.find(params[:id]) or raise ActiveRecord::RecordNotFound
    @followed = current_user&.packs&.find_by(catalog_id: @pack.catalog_id)
  end

  def follow
    pack = begin
      OfficialCatalog.follow(current_user, params[:id])
    rescue ActiveRecord::RecordInvalid => error
      return redirect_back_or_to catalog_path(params[:id]), alert: error.record.errors.full_messages.to_sentence
    end
    if params[:practice]
      redirect_to play_path(list: pack.word_lists.first.id)
    else
      redirect_to packs_path(pack: pack.id), notice: helpers.tt("wordLists.catalog.followed", name: pack.name)
    end
  end

  def unfollow
    pack = current_user.packs.find_by!(catalog_id: params[:id])
    pack.destroy
    # typle-r stays where the pack was unfollowed (the word packs list or the official pack).
    redirect_back_or_to catalog_path(params[:id]), notice: helpers.tt("wordLists.follow.done", name: pack.name), status: :see_other
  end
end
