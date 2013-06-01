class Commit < ActiveRecord::Base
  attr_accessible :files, :sha, :timestamp
  belongs_to :repository
  serialize :files

  before_save :request_files

  def request_files
    self.files = repository.github.commits.find(sha: sha).files.map{|f| [f.filename, f.additions, f.deletions] }
  end
end
