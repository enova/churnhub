class AddCommitterIdToCommits < ActiveRecord::Migration
  def change
    add_column :commits, :committer_id, :integer
  end
end
