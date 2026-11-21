# typle-r's /result: a practice result someone shared, read from the link itself.
class SharedResultsController < ApplicationController
  allow_unauthenticated_access

  def show
    @result = SharedResult.from_query(params)
  end
end
