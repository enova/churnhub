class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :login
      t.string :oauth_token

      t.timestamps
    end
  end
end
