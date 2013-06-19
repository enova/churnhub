class Committer < ActiveRecord::Base
  attr_accessible :email, :name, :gravatar_url
  has_many :commits

  def as_json options = {}
    super options.reverse_merge include: :commits
  end

  def fetch_user_info_from_github_if_incomplete! client
  end
end
