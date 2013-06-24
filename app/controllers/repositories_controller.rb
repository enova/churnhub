class RepositoriesController < ApplicationController
  respond_to :json, :html

  def index
    @repository   = Repository.new
    @repositories = viewed_repositories.map do |id|
      Repository.find id
    end
  end

  def create
    @repository = Repository.with_url(params[:repository][:url])
    if @repository.valid?
      redirect_to commits_path(@repository.url)
    else
      render 'index'
    end
  end
end
