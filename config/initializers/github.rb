module Churnhub
  class Github
    def initialize path, host='github.com'
      @path = path

      @client = Octokit::Client.new
      if host != 'github.com'
        @client.api_endpoint = "https://#{host}/api/v3"
        @client.web_endpoint = "https://#{host}/"
      end
    end

    def shas
      @client.commits(@path).map &:sha
    end

    def commit_by_sha sha
      commit_json, files_json = @client.commit(@path, sha).values_at("commit", "files")
      { timestamp: commit_json.committer.date,
        files: files_json.map do |f|
          f.values_at "filename", "additions", "deletions"
        end
      }
    end
  end
end
