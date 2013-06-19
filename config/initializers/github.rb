require_relative './github_url.rb'

module Churnhub
  class Github
    include Churnhub::Url
    attr_reader :url

    def initialize token, url
      @url = url

      @client = Octokit::Client.new
      @client.per_page       = 100

      if host == 'github.com'
        @client.client_id      = ENV["GITHUB_ID"]
        @client.client_secret  = ENV["GITHUB_SECRET"]
        @client.oauth_token    = token
      else
        @client.api_endpoint   = "https://#{host}/api/v3"
        @client.web_endpoint   = "https://#{host}/"
      end
    end

    def shas start, finish, branch="master"
      start = start.strftime "%Y-%m-%d" if !start.is_a? String
      finish = finish.strftime "%Y-%m-%d" if !finish.is_a? String
      @client.commits_between(@path, start, finish, branch).map &:sha
    end

    def commit_by_sha sha
      commit_json, files_json, github_committer_json = @client.commit(@path, sha).values_at("commit", "files", "committer")
      { timestamp: commit_json.committer.date,
        committer: { name: commit_json.committer.name,
                    email: commit_json.committer.email,
             gravatar_url: 
               begin
                 "http://www.gravatar.com/avatar/#{github_committer_json.gravatar_id}"
               rescue NoMethodError
                 "http://placedog.it/80/80"
               end
                   },
        files: files_json.map do |f|
          f.values_at "filename", "additions", "deletions"
        end
      }

    end

    def self.user_details token
      response = Octokit::Client.new(oauth_token: token).get('/user').slice "name", "login", "gravatar_id"
      { user_name: response.name,
        user_login: response.login,
        user_github_profile: "https://github.com/#{response.login}",
        user_thumbnail:
          if response.gravatar_id
            "http://www.gravatar.com/avatar/#{response.gravatar_id}"
          else
            "http://placedog.it/80/80"
          end
      }
    end
  end
end
