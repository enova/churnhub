class RepositoriesController < ApplicationController
  respond_to :json, :html
  def index
    @repository = Repository.new
  end

  def create
    redirect_to repo_path(Repository.clean_url(params[:repository][:url]))
  end

  def show
    @repository = Repository.find_or_create_by_url Repository.clean_url(params[:url])
    respond_with @repository
  end
end
