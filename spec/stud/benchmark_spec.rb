require "stud/benchmark"
require "spec_env" # from the top level spec/ directory

describe Stud::Benchmark do
  context ".run(N)" do
    it "should run N times" do
      results = Stud::Benchmark.run(100) { }
      insist { results.instance_eval { @data }.count } == 100
    end
  end

  context ".runtimed(N)" do
    it "should run for N seconds" do
      start = Time.now
      seconds = 1
      Stud::Benchmark.runtimed(seconds) { }
      duration = Time.now - start

      # Permit some skew
      insist { (seconds * 0.85) .. (seconds * 1.15) }.include?(duration)
    end
  end

  context ".cputimed(N)" do
    it "should run for N seconds" do
      start = Time.now
      seconds = 1
      Stud::Benchmark.cputimed(seconds) { }
      duration = Time.now - start

      # Permit some skew
      insist { (seconds * 0.85) .. (seconds * 1.15) }.include?(duration)
    end
  end
end
