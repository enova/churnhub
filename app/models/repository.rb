class Repository < ActiveRecord::Base
  after_save      :fetch_commits_from_github
  has_many        :commits, dependent: :destroy
  validates       :url, presence: true, uniqueness: true
  attr_accessible :url
  attr_reader     :path

  def fetch_commits_from_github
    github.shas.each do |sha|
      commits.create sha: sha,
               timestamp: nil,
                   files: nil
    end
  end

  def github
    @github ||= Churnhub::Github.new path, host
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
