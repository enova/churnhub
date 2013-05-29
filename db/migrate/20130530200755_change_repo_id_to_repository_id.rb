class ChangeRepoIdToRepositoryId < ActiveRecord::Migration
  def change
    rename_column :commits, :repo_id, :repository_id
  end
end
