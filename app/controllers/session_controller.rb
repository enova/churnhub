class SessionController < ApplicationController
  def signin
    redirect_to GithubOAuth.authorize_url ENV["GITHUB_ID"], ENV["GITHUB_TOKEN"]
  end

  def auth
    session[:access_token] = GithubOAuth.token ENV["GITHUB_ID"], ENV["GITHUB_TOKEN"], params[:code]
    redirect_to '/'
  end

  def signout
    session[:access_token] = nil
  end
end
