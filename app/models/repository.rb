class Repository < ActiveRecord::Base
  after_save      :fetch_commits_from_github
  attr_accessible :url
  has_many        :commits, dependent: :destroy
  validates       :url, presence: true, uniqueness: true

  def as_json options = {}
    options.reverse_merge! include: :commits
    super options
  end

  def fetch_commits_from_github
    github.commits.all.each do |c|
      commits.create sha: c.sha, timestamp: c.commit.author.date
    end
  end

  def github
    @github ||= Github::Repos.new do |config|
      host, config.user, config.repo = url.split('/')
      if host != "github.com"
        config.endpoint = "https://#{host}/api/v3"
        config.site     = "https://#{host}"
      end
    end
  end

  def url= _url
    self[:url] = Repository.clean_url(_url)
  end

  def self.with_url _url
    where(url: clean_url(_url)).first_or_create
  end

  def self.clean_url _url
    _url.sub(/^[^\/]*(?:\/\/|@)/,'').sub(/\.git/,'')
  end
end
