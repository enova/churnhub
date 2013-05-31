class RepositoriesController < ApplicationController
  respond_to :json, :html
  def index
    @repository = Repository.new
  end

  def create
    @repository = Repository.with_url(params[:url])
    redirect_to @repository
  end

  def show
    @repository = Repository.with_url(params[:url])
    respond_with @repository
  end
end
