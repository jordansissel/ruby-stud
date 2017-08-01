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

    it "should support stop! and stop?" do
      start_time = Time.now
      task = Stud::Task.new do
        sleep(100)
        Stud.stop?
      end

      # make sure the task enters the sleep method
      sleep(1)

      task.stop!
      result = task.wait

      insist { result } == true
      insist { task.stop? } == true
      insist { Time.now - start_time } < 2
    end

    it "should not error stopping twice" do
      task = Stud::Task.new do
        sleep 100
        Stud.stop?
      end

      sleep 1

      task.stop!

      expect do
        task.stop!
      end.not_to raise_error()
    end
  end
end
