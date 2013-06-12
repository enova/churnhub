class DeleteUsersTable < ActiveRecord::Migration
  def up
    drop_table :users
  end

  def down
    create_table :users do |t|
      t.string :login
      t.string :oauth_token

      t.timestamps
    end
  end
end
