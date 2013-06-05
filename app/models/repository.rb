class Repository < ActiveRecord::Base
  after_save      :fetch_commits_from_github
  has_many        :commits, dependent: :destroy
  validates       :url, presence: true, uniqueness: true
  attr_accessible :url
  attr_reader :path

  def as_json options = {}
    options.reverse_merge! include: :commits
    super options
  end

  def fetch_commits_from_github
    github.commits(path).each do |commit|
      commits.create sha: commit.sha,
               timestamp: commit.commit.committer.date
    end
  end

  def github
    return @github if @github

    @github = Octokit::Client.new
    
    if host != 'github.com'
      @github.api_endpoint = "https://#{host}/api/v3"
      @github.web_endpoint = "https://#{host}/"
    end

    @github
  end

  def host
    @host || (@host, @path = url.split '/', 2)
    @host
  end

  def path
    @path || (@host, @path = url.split '/', 2)
    @path
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
