class SessionController < ApplicationController
  skip_before_filter :store_target_url

  def signin
    redirect_to session[:target_url] and return if session[:access_token]
    redirect_to GithubOAuth.authorize_url ENV["GITHUB_ID"], ENV["GITHUB_SECRET"]
  end

  def auth
    session[:access_token] = GithubOAuth.token ENV["GITHUB_ID"], ENV["GITHUB_SECRET"], params[:code]
    session[:current_user] = Churnhub::Github.user_details session[:access_token]
    redirect_to session[:target_url]
  end

  def signout
    session[:access_token] = nil
    session[:current_user] = nil
    redirect_to '/'
  end
end
