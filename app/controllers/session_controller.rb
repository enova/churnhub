class SessionController < ApplicationController
  skip_before_filter :store_target_url

  def signin
    redirect_to session[:target_url] and return if session[:access_token]
    redirect_to GithubOAuth.authorize_url ENV["GITHUB_ID"], ENV["GITHUB_TOKEN"]
  end

  def auth
    session[:access_token] = GithubOAuth.token ENV["GITHUB_ID"], ENV["GITHUB_TOKEN"], params[:code]
    user_data = Churnhub::Github.user_details session[:access_token]
    session[:user_name] = user_data.name
    session[:user_login] = user_data.login
    session[:user_github_profile] = "https://github.com/#{user_data.login}"
    redirect_to session[:target_url]
  end

  def signout
    session[:access_token] = nil
    session[:user_name] = nil
    session[:user_login] = nil
    session[:user_github_profile] = nil
    redirect_to '/'
  end
end
