class Commit < ActiveRecord::Base
  attr_accessible :sha, :timestamp
  belongs_to :repository
  belongs_to :committer
  has_many :commit_files
  has_many :files, class_name: 'CommitFile'
  has_many :file_infos, through: :commit_files

  scope :between, ->(start, finish){ where(timestamp: start..finish)}

  def as_json options = {}
    super options.reverse_merge include: {
      committer: {
        only: [:email, :name]
      },
      files: {
        methods: :filename,
        only: [:additions, :deletions],
      }
    },
    only: [:id, :sha, :timestamp]
  end

  def fetch_files_from_github_if_incomplete! client
    return if self.timestamp

    self.timestamp, committer_hash, files = client.commit_by_sha(sha).values_at :timestamp, :committer, :files

    files.each do |file|
      record = file_infos.where(name: file[0]).first_or_create
      commit_files.where(file_info_id: record.id).first_or_create.update_fields! additions: file[1],
                                                                                 deletions: file[2]
    end

    committer = Committer.new committer_hash
    committer.save
    self.committer_id = committer.id

    save
  end
end
