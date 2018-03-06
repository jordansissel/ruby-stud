require "stud/temporary"
require "spec_env" # from the top level spec/ directory

describe Stud::Temporary do
  include Stud::Temporary # make these methods available in scope

  describe "#temp_root" do
    it "should return a string" do
      insist { temp_root }.is_a?(String)
    end

    it "should respect TMP" do
      old = ENV["TMP"]
      ENV["TMP"] = "/pants"
      # Make sure the root was changed to /pants
      insist { temp_root } == ENV["TMP"]
      ENV["TMP"] = old
    end
  end

  describe "#pathname" do
    it "should return a string" do
      insist { pathname }.is_a?(String)
    end

    it "should respect TMP" do
      old = ENV["TMP"]
      ENV["TMP"] = "/pants"
      # Make sure the leading part of the pathname is /pants/
      insist { pathname } =~ Regexp.new("^#{Regexp.quote(ENV["TMP"])}/")
      ENV["TMP"] = old
    end
  end

  describe "#file" do
    context "without a block" do
      subject { file }

      after(:each) do
        subject.close
        File.delete(subject)
      end

      it "should return a File" do
        insist { subject }.is_a?(File)
      end
    end # without a block

    context "with a block" do
      it "should pass a File to the block" do
        path = ""
        file { |fd| insist { fd }.is_a?(File) }
      end

      it "should clean up after the block closes" do
        path = ""
        file { |fd| path = fd.path }
        reject { File }.exists?(path)
      end
    end # with a block
  end # #file
end
