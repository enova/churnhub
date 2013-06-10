class User < ActiveRecord::Base
  attr_accessible :login, :oauth_token
end
