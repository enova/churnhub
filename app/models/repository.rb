class Repository < ActiveRecord::Base
  attr_accessible :url

  validates :url, presence: true
end
