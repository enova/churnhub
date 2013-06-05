class Commit < ActiveRecord::Base
  attr_accessible :files, :sha, :timestamp
  belongs_to :repository
  serialize :files

  scope :between, ->(start, finish){ where(timestamp: start..finish)}

  before_save :request_files

  def request_files
    self.files = repository.github.commit(repository.path, sha).files.map do |f|
      [f.filename, f.additions, f.deletions]
    end
  end
end
