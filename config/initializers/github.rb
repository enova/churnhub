module Churnhub
  class Github
    def initialize token, path, host='github.com'
      @path = path

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
      commit_json, files_json = @client.commit(@path, sha).values_at("commit", "files")
      { timestamp: commit_json.committer.date,
        files: files_json.map do |f|
          f.values_at "filename", "additions", "deletions"
        end
      }
    end

    def self.user_details token
      user = Octokit::Client.new(oauth_token: token).get('/user').slice "name", "login"
      user.merge url: "https://github.com/#{user[:login]}"
    end
  end
end
