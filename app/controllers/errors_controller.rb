# Pages that are not there (typle-r's 404), for unknown paths and, in production, as the exceptions app's 404.
class ErrorsController < ApplicationController
  allow_unauthenticated_access

  def not_found
    render "errors/not_found", status: :not_found, formats: :html
  end
end
