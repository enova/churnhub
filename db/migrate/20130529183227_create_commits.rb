class CreateCommits < ActiveRecord::Migration
  def change
    create_table :commits do |t|
      t.integer :repo_id
      t.string :sha
      t.text :files
      t.datetime :timestamp

      t.timestamps
    end
  end
end
