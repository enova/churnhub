require 'spec_helper'

describe Repository do
  it "cleans url on assignment" do
    repo = Repository.new url: "http://git.ab.com/u/r.git"
    repo.url.should == "git.ab.com/u/r"
  end

  describe :with_url, :vcr do
    it "creates non-existant repos" do
      expect {Repository.with_url "github.com/jeffpeterson/irc"}.to change{Repository.count}.by(1)
    end
  end

  describe :clean_url do
    it "passes clean urls through" do
      Repository.clean_url("git.ab.com/u/r").should       == "git.ab.com/u/r"
      Repository.clean_url("git.com/DB/g.raphael").should == "git.com/DB/g.raphael"
    end

    it "removes ssh-style git urls" do
      Repository.clean_url("git@git.ab.com/u/r").should == "git.ab.com/u/r"
    end

    it "works with repo names with dots" do
      Repository.clean_url("http://github.com/D/g.raphael.git").should == "github.com/D/g.raphael"
    end
  end
end
