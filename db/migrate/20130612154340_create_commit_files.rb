class CreateCommitFiles < ActiveRecord::Migration
  def change
    create_table :commit_files do |t|
      t.integer :file_info_id
      t.integer :commit_id
      t.integer :additions
      t.integer :deletions

      t.timestamps
    end
  end
end
