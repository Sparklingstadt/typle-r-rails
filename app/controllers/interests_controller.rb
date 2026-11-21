# 関心: what the user is interested in, and a switch for every official pack that fits, to follow or unfollow it.
class InterestsController < ApplicationController
  def show
    @ids = current_user.interest_ids
    @packs = OfficialCatalog.packs.select { |pack| Interests.matches?(pack, @ids) }
    @followed = current_user.packs.where.not(catalog_id: nil).pluck(:catalog_id).to_set
  end

  def update
    current_user.update!(interests: Interests.normalize(params[:interests]))
    redirect_to interests_path, notice: t(".saved")
  end

  # Follows exactly the packs switched on among those shown; a pack switched off is unfollowed with its records.
  def packs
    shown = Array(params[:shown]).map(&:to_s)
    on = Array(params[:follow]).map(&:to_s).to_set
    Pack.transaction do
      shown.each do |catalog_id|
        followed = current_user.packs.find_by(catalog_id:)
        if on.include?(catalog_id) && !followed
          OfficialCatalog.follow(current_user, catalog_id)
        elsif !on.include?(catalog_id) && followed
          followed.destroy
        end
      end
    end
    redirect_to interests_path, notice: t(".saved")
  end
end
