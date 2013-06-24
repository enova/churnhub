class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_user, :record_repository_as_viewed, :viewed_repositories
  before_filter :store_target_url

  def current_user
    @current_user ||= session[:current_user]
  end

  def record_repository_as_viewed repo
    session[:viewed_repositories] = [] unless session[:viewed_repositories]
    session[:viewed_repositories] << @repository.id unless session[:viewed_repositories].include? @repository.id
  end

  def viewed_repositories
    session[:viewed_repositories] ||= []
  end

  protected

  def store_target_url
    session[:target_url] = request.url.sub /\.json/, ''
  end
end
