class CommitFile < ActiveRecord::Base
  attr_accessible :additions, :commit_id, :deletions, :file_info_id
  belongs_to :file_info
  belongs_to :commit
end
