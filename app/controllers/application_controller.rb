class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :store_target_url

  protected

  def store_target_url
    session[:target_url] = request.url
  end
end
