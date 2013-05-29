class Repository < ActiveRecord::Base
  attr_accessible :url, :files

  serialize :files

  before_save :format_url, :fetch_diff_from_github

  validates :url, presence: true, uniqueness: true

  def fetch_diff_from_github
    response = github.commits.compare github.user, github.repo, last_sha, "HEAD"
    self.files = response.files
  end

  def last_sha
    @last_sha ||= github.commits.all.to_a.last.sha
  end

  def github
    @github ||= Github::Repos.new do |config|
        host, config.user, config.repo = parsed_url
        if host != "github.com"
          config.endpoint = "https://#{host}/api/v3"
          config.site     = "https://#{host}"
        end
    end
  end

  def parsed_url
    @parsed_url ||= /(?<=:\/\/|@|^)([^\/]+)(?:\/|:)([^\/]+)\/([^\/\.]+)/i.match(url).captures
  end

  def format_url
    self.url = parsed_url.join("/")
  end
end
