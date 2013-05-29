class RemoveFilesFromRepository < ActiveRecord::Migration
  def change
    remove_column :repositories, :files
  end
end
