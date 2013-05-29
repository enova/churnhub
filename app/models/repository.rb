class Repository < ActiveRecord::Base
  attr_accessible :url

  after_save :fetch_diff_from_github

  validates :url, presence: true, uniqueness: true

  has_many :commits, dependent: :destroy

  def fetch_diff_from_github
    github.commits.all.each do |c|
      commits.create sha: c.sha,
                   files: get_file_stats(c.sha),
               timestamp: c.commit.author.date
    end
  end

  def get_file_stats sha
    github.commits.find(github.user, github.repo, sha).files.map{|f| [f.filename, f.additions, f.deletions]}
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
