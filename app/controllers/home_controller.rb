class HomeController < ApplicationController
  def show
    @dashboard = Dashboard.new(current_user)
  end

  # The dashboard's trends, which the home page loads into its frame once the section scrolls near.
  def trends
    return redirect_to home_path unless turbo_frame_request?
    render partial: "home/trends", locals: { dashboard: Dashboard.new(current_user) }
  end
end
