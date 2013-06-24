class CommitsController < ApplicationController
  skip_before_filter :store_target_url, only: [:show]
  respond_to :json, :html

  def index
    @repository = Repository.with_url params[:url]
    if !session[:access_token] && (@repository.host == 'github.com')
      redirect_to '/signin' and return
    end

    record_repository_as_viewed @repository

    @repository.github = Churnhub::Github.new session[:access_token], @repository.url

    respond_to do |format|
      format.html do

        respond_with @commits
      end

      format.json do
        @repository.fetch_commits_from_github
        @commits = @repository.commits
        respond_with @commits
      end
    end


  end

  def show
    @commit = Commit.find params[:id]
    client = Churnhub::Github.new session[:access_token], @commit.repository.url
    @commit.fetch_files_from_github_if_incomplete! client
    respond_with @commit
  end
end
