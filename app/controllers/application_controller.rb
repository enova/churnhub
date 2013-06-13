class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :store_target_url
  before_filter :get_user_data

  protected

  def get_user_data
    @user = Churnhub::Github.user_details session[:access_token] if session[:access_token]
  end

  def store_target_url
    session[:target_url] = request.url.sub /\.json/, ''
  end
end
