class Commit < ActiveRecord::Base
  attr_accessible :sha, :timestamp
  belongs_to :repository
  has_many :commit_files
  has_many :file_infos, through: :commit_files

  scope :between, ->(start, finish){ where(timestamp: start..finish)}

  def fetch_files_from_github_if_incomplete! token
    return if self.timestamp

    self.timestamp, files = repository.github(token).commit_by_sha(sha).values_at :timestamp, :files
    files.each do |file|
      record = file_infos.where(name: file[0]).first_or_create
      commit_files.where(file_info_id: record.id).first_or_create.update_fields! additions: file[1],
                                                                                 deletions: file[2]
    end

    save
  end
end
