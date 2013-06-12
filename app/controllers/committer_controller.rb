class CommitterController < ApplicationController
  respond_to :json, :html

  def show
    respond_with Committer.find params[:id]
  end
end
