class CommitsController < ApplicationController
  respond_to :json, :html

  def index
    params.reverse_merge! start: 3.months.ago, finish: Date.today

    @repository = Repository.with_url params[:url]
    @commits    = @repository.commits.between(params[:start], params[:finish])

    respond_with @commits
  end
end
