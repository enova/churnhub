class Committer < ActiveRecord::Base
  attr_accessible :email, :name
  has_many :commits

  def as_json options = {}
    super options.reverse_merge include: :commits
  end
end
