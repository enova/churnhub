class Commit < ActiveRecord::Base
  attr_accessible :files, :sha, :timestamp
  belongs_to :repository
  serialize :files

  scope :between, ->(start, finish){ where(timestamp: start..finish)}

  after_find :fetch_files_from_github_if_incomplete!

  def fetch_files_from_github_if_incomplete!
    self.timestamp, self.files = repository.github.commit_by_sha(sha).values_at :timestamp, :files
    save
  end
end
