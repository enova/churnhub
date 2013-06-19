class AddGravatarUrlToCommitters < ActiveRecord::Migration
  def change
    add_column :committers, :gravatar_url, :string
  end
end
