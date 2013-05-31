class Repository < ActiveRecord::Base
  attr_accessible :url, :files
  serialize :files

  before_save :fetch_diff_from_github

  validates :url, presence: true, uniqueness: true

  def self.with_url _url
    where(url: clean_url(_url)).first_or_create
  end

  def fetch_diff_from_github
    latest_commit = github.commits.get sha: "HEAD"

    self.files = latest_commit.files.map do |file|
      file.values_at :filename, :additions, :deletions
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

  def self.clean_url _url
    _url.sub(/^[^\/]*(?:\/\/|@)/,'').sub(/\.git/,'')
  end
end
