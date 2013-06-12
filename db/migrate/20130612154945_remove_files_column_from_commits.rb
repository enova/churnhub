class RemoveFilesColumnFromCommits < ActiveRecord::Migration
  def up
    remove_column :commits, :files
  end

  def down
    add_column :commits, :files, :text
  end
end
