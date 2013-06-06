class Commit < ActiveRecord::Base
  attr_accessible :files, :sha, :timestamp
  belongs_to :repository
  serialize :files

  scope :between, ->(start, finish){ where(timestamp: start..finish)}

  before_save :request_files

  def request_files
    timestamp, files = repository.github.commit_by_sha sha
  end
end
