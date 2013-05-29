class AddFilesToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :files, :text
  end
end
