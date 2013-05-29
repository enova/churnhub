class Commit < ActiveRecord::Base
  attr_accessible :repository_id, :files, :sha, :timestamp
  belongs_to :repository
  serialize :files
end
