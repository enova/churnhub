class Repository < ActiveRecord::Base
  has_many        :commits, dependent: :destroy
  validates       :url, presence: true, uniqueness: true
  attr_accessible :url
  attr_reader     :path

  def fetch_commits_from_github token, start=3.months.ago, finish=Date.today
    github(token).shas(start, finish).each do |sha|
      commits.where(sha: sha).first_or_create sha: sha,
                                        timestamp: nil
    end
  end

  def github token
    @github ||= Churnhub::Github.new token, path, host
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
