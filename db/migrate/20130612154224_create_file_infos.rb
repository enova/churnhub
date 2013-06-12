class CreateFileInfos < ActiveRecord::Migration
  def change
    create_table :file_infos do |t|
      t.string :name

      t.timestamps
    end
  end
end
