class Repository < ActiveRecord::Base
  attr_accessor :files
  attr_accessible :url

  validates :url, presence: true

  def fetch_from_github!
    uri = URI(self.url)
    g = Github.new do |config|
        if uri.host != "github.com"
          config.endpoint    = 'https://#{uri.host}/api/v3'
          config.site        = 'https://#{uri.host}'
        end
#       config.oauth_token = ''
    end

    response = g.repos.commits.compare *uri.path.match(%r{/([^/]+)/([^\./]+)}).captures, "HEAD~1000", "HEAD"
  rescue
    last = g.repos.commits.all.to_a.last
    response = g.repos.commits.compare *uri.path.match(%r{/([^/]+)/([^\./]+)}).captures, last.sha, "HEAD"
  ensure
    self.files = response.files
  end
end
