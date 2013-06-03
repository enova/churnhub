class RepositoriesController < ApplicationController
  respond_to :json, :html
  def index
    @repository = Repository.new
  end

  def create
    @repository = Repository.with_url(params[:repository][:url])
    redirect_to repo_path(@repository.url)
  end

  def show
    @repository = Repository.with_url(params[:url])
    respond_with repo_path(@repository.url)
  end
end
