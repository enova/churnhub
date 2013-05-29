class Repository < ActiveRecord::Base
  attr_accessible :url, :files
  serialize :files

  before_save :fetch_diff_from_github

  validates :url, presence: true, uniqueness: true

  def fetch_diff_from_github
    response = github.commits.compare(github.user, github.repo, last_sha, "HEAD")

    self.files = response.files.map do |file|
      file.values_at *%w[filename additions deletions]
    end
  end

  def last_sha
    @last_sha ||= github.commits.all.to_a.last.sha
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
    _url[/(?<=\/\/|@|^)([^\/\n]+\/[^\/\n]+\/[^\.\/\n]+)/]
  end
end
