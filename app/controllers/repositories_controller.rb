class RepositoriesController < ApplicationController
  respond_to :json, :html
  def index
    redirect_to '/signin' unless session[:access_token]

    @repository   = Repository.new
    @repositories = Repository.all
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
