class CommitsController < ApplicationController
  skip_before_filter :store_target_url, only: [:show]
  respond_to :json, :html

  def index
    params.reverse_merge! start: 1.year.ago, finish: Date.today

    @repository = Repository.with_url params[:url]
    if !session[:access_token] && (@repository.host == 'github.com')
      redirect_to '/signin' and return
    end

    respond_to do |format|
      format.html do

        respond_with @commits
      end

      format.json do
        @repository.fetch_commits_from_github session[:access_token], params[:start], params[:finish]
        @commits = @repository.commits
        respond_with @commits
      end
    end


  end

  def show
    @commit = Commit.find params[:id]
    @commit.fetch_files_from_github_if_incomplete! session[:access_token]
    respond_with @commit
  end
end
