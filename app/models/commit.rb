class Commit < ActiveRecord::Base
  attr_accessible :files, :sha, :timestamp
  belongs_to :repository
  serialize :files

  scope :between, ->(start, finish){ where(timestamp: start..finish)}

  def fetch_files_from_github_if_incomplete! token
    return if self.timestamp || self.files
    self.timestamp, self.files = repository.github(token).commit_by_sha(sha).values_at :timestamp, :files
    save
  end
end
