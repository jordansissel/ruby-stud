require "stud/task"
require "spec_env" # from the top level spec/ directory

describe Stud::Task do
  context "#wait" do
    it "should return the return value of the Task block" do
      task = Stud::Task.new { "Hello" }
      insist { task.wait } == "Hello"
    end

    it "should raise exception if the Task block raises such" do
      task = Stud::Task.new { raise Insist::Failure }
      insist { task.wait }.fails
    end
  end
end
