class CommitsController < ApplicationController
  respond_to :json, :html

  def index
    @repository = Repository.with_url params[:url]
    @commits    = @repository.commits

    respond_with @commits
  end
end
