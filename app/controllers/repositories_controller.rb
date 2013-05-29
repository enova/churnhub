class RepositoriesController < ApplicationController
  def index
    @repository = Repository.new
  end

  def create
    if @repository = Repository.where(params[:repository]).first_or_create
      redirect_to repo_path(@repository.url)
    else
      render :edit
    end
  end

  def show
    @repository = Repository.find params[:id]
  end

  def repo
    @repository = Repository.find_by_url params[:url]
    render 'show'
  end
end
