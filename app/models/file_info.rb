class FileInfo < ActiveRecord::Base
  attr_accessible :name
  has_many :commit_files
  has_many :commits, through: :commit_files
end
