class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user
  before_filter :store_target_url

  def current_user
    @current_user ||= session[:current_user]
  end

  protected

  def store_target_url
    session[:target_url] = request.url.sub /\.json/, ''
  end
end
