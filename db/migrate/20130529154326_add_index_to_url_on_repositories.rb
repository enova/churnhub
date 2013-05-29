class AddIndexToUrlOnRepositories < ActiveRecord::Migration
  def change
    add_index :repositories, :url
  end
end
