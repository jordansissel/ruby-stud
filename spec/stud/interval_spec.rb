require "stud/interval"
require "spec_env" # from the top level spec/ directory

describe Stud do
  describe "#interval" do
    let(:interval) { 1 }
    it "allows the interval to sleep before running" do
      start_time = Time.now

      Stud.interval(interval, :sleep_then_run => true) do
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

    it 'should be able to interrupt an interval defined as a task' do
      counter = 0

      task = Stud::Task.new do
        Stud.interval(0.5) do
          counter += 1
          task.stop!
        end
      end

      sleep(1)

      expect(counter).to eq(1)
    end

    it 'should be able to wake up from an sleep' do
      counter = 0

      task = Stud::Task.new do
        Stud.interval(2) do
          counter += 1
        end
      end
      task.stop!
      sleep(0.5)
      expect(task.status).to eq("sleep")
      task.wakeup
      expect(task.status).to eq("run")
      expect(counter).to eq(1)
    end
  end
end
