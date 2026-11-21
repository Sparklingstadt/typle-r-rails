class PagesController < ApplicationController
  allow_unauthenticated_access

  TRY_CATALOG_ID = "pack-english-basic-words"

  def landing
    @packs = OfficialCatalog.packs
    @starters = starter_ids.filter_map { |id| OfficialCatalog.find(id) }
    # As typle-r's src/app/page.tsx: the hero's words come from the first list of the English basics pack.
    @try_pack = OfficialCatalog.find(TRY_CATALOG_ID)
    @try_list = @try_pack&.lists&.first
    @try_words = @try_list&.words&.first(10) || []
  end

  def about
  end

  def guide
  end

  # typle-r's /about/licenses, and its third-party.txt as /about/licenses.txt.
  def licenses
    respond_to do |format|
      format.html { @entries = ThirdPartyLicenses.entries }
      format.text { render plain: ThirdPartyLicenses.full_text }
    end
  end

  # typle-r's /shared/[id]: pack sharing has ended, and a link handed out says so.
  def shared_pack
  end

  private
    def starter_ids = PracticeController::STARTER_CATALOG_IDS
end
