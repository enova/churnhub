module Churnhub::Url
  def host
    @host || (@host, @path = url.split '/', 2)
    @host
  end

  def path
    @path || (@host, @path = url.split '/', 2)
    @path
  end

  def url= _url
    self[:url] = Churnhub::Url.clean_url(_url)
  end

  def self.clean_url url
    url.sub(/^[^\/]*(?:\/\/|@)/,'').sub(/\.git/,'')
  end
end
