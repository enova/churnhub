class RepositoriesController < ApplicationController
  def index
    @repository = Repository.new
  end

  def create
    @repository = Repository.new params[:repository]
    if @repository.save
      redirect_to @repository
    else
      render :edit
    end
  end

  def show
    @repository = Repository.find params[:id]
    @repository.fetch_from_github!
  end
end
