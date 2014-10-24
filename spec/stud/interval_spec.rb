require "stud/interval"
require "spec_env" # from the top level spec/ directory

describe Stud do
  describe "#interval" do
    let(:interval) { 5 }
    it "Allow the interval to sleep before running the block" do
      start_time = Time.now

      Stud.interval(interval, :sleep_than_run => true) do
        end_time = Time.now
        expect(end_time - start_time).to be >= interval
        break
      end
    end

    it "defaults to run than sleep" do
      start_time = Time.now

      Stud.interval(interval) do
        end_time = Time.now
        expect(end_time - start_time).to be < interval
        break
      end
    end
  end
end
