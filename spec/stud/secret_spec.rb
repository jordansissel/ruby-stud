require "stud/secret"
require "spec_env" # from the top level spec/ directory

describe Stud::Secret do
  subject { Stud::Secret.new("hello") }
  it "should hide the secret value from inspection" do
    insist { subject.inspect } == "<secret>"
    insist { subject.to_s } == "<secret>"
  end

  context "#value" do
    it "should expose the secret value" do
      insist { subject.value } == "hello"
    end
  end
end
