class Repository < ActiveRecord::Base
  include Churnhub::Url
  has_many        :commits, dependent: :destroy
  validates       :url, presence: true, uniqueness: true
  attr_reader     :github

  def fetch_commits_from_github start=3.months.ago, finish=Date.today
    github.shas(start, finish).each do |sha|
      commits.where(sha: sha).first_or_create sha: sha,
                                        timestamp: nil
    end
  end

  def github= client
    @github = client
  end

  def self.with_url _url
    where(url: Churnhub::Url.clean_url(_url)).first_or_create
  end
end
