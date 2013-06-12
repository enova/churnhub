# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130612185703) do

  create_table "commit_files", :force => true do |t|
    t.integer  "file_info_id"
    t.integer  "commit_id"
    t.integer  "additions"
    t.integer  "deletions"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "commits", :force => true do |t|
    t.integer  "repository_id"
    t.string   "sha"
    t.datetime "timestamp"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "committer_id"
  end

  create_table "committers", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "file_infos", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "repositories", :force => true do |t|
    t.string   "url"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "repositories", ["url"], :name => "index_repositories_on_url"

end
