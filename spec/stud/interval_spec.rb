require "stud/interval"
require "stud/task"
require "spec_env" # from the top level spec/ directory

describe Stud do

  before(:each) do
    # clear STUD_STOP_REQUESTED in current thread
    Thread.current[Stud::STUD_STOP_REQUESTED] = nil
  end

  describe "#stoppable_sleep" do
    let(:error_margin) { 0.02 }

    [0.5, 1.2].each do |duration|
      it "should sleep for the required interval without stopping" do
        start_time = Time.now

        returned_sleep_time = Stud.stoppable_sleep(duration)

        expect(Time.now - start_time).to be_within(error_margin).of(duration)
        expect(returned_sleep_time).to be_within(error_margin).of(duration)
      end
    end

    it "should support the Stud.stop? predicate by default" do
      start_time = Time.now

      Stud.stop!
      returned_sleep_time = Stud.stoppable_sleep(10)

      expect(Time.now - start_time).to be_within(error_margin).of(1)
      expect(returned_sleep_time).to be_within(error_margin).of(1)
    end

    [0.2, 0.5, 1].each do |check_interval|
      it "should stop sleep immediately using check interval and condition block" do
        start_time = Time.now

        returned_sleep_time = Stud.stoppable_sleep(10, check_interval) { true }

        expect(Time.now - start_time).to be_within(error_margin).of(check_interval)
        expect(returned_sleep_time).to be_within(error_margin).of(check_interval)
      end

      it "should stop sleep after a few sleep iterations using check interval and condition block" do
        check_count = 0

        start_time = Time.now

        returned_sleep_time = Stud.stoppable_sleep(10, check_interval) { (check_count += 1) >= 3 }

        expect(Time.now - start_time).to be_within(error_margin).of(check_count * check_interval)
        expect(returned_sleep_time).to be_within(error_margin).of(check_count * check_interval)
      end
    end
  end

  describe "#interval" do

    let(:interval) { 1 }

    it "defaults to run than sleep" do
      start_time = Time.now

      Stud.interval(interval) do
        end_time = Time.now
        expect(end_time - start_time).to be < interval
        break
      end
    end

    it 'should be able to interrupt an interval within same thread' do
      counter = 0

      Stud.interval(0.5) do
        counter += 1
        Stud.stop!
      end

      expect(counter).to eq(1)
    end

    it 'should be able to interrupt an interval from different threads' do
      counter = 0

      start_time = Time.now
      t = Thread.new do
        Stud.interval(10) do
          counter += 1
        end
      end

      sleep(1)
      Stud.stop!(t)
      t.join

      # the execution time worst case should be the sleep(1) call plus a sleep(1) in
      # the interval loop before seeing the stop? and maybe a "remainder" sleep(< 1)
      # so < 3 should be safe.
      expect(Time.now - start_time).to be < 3
      expect(counter).to eq(1)
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

    it "should support both stop? and interrupted?" do
      Stud.interval(10) do
        Stud.stop!
      end
      expect(Stud.stop?).to be_truthy
      expect(Stud.interrupted?).to be_truthy
    end

    context "when sleeping first" do
      let(:interval_options) { {:sleep_then_run => true} }

      it "allows the interval to sleep before running" do
        start_time = Time.now

        Stud.interval(interval, interval_options) do
          end_time = Time.now
          expect(end_time - start_time).to be >= interval
          break
        end
      end

      it 'should be able to interrupt an interval defined as a task' do
        counter = 0

        start_time = Time.now
        task = Stud::Task.new do
          Stud.interval(10, interval_options) do
            counter += 1
          end
        end

        sleep(1)
        task.stop!
        task.wait

        # the execution time worst case should be the sleep(1) call plus a sleep(1) in
        # the interval loop before seeing the stop? and maybe a "reminder" sleep(< 1)
        # so < 3 should be safe.
        expect(Time.now - start_time).to be < 3
        expect(counter).to eq(0)
      end

      it 'should be able to interrupt an interval from different threads' do
        counter = 0

        start_time = Time.now
        t = Thread.new do
          Stud.interval(10, :sleep_then_run => true) do
            counter += 1
          end
        end

        sleep(1)
        Stud.stop!(t)
        t.join

        # the execution time worst case should be the sleep(1) call plus a sleep(1) in
        # the interval loop before seeing the stop? and maybe a "reminder" sleep(< 1)
        # so < 3 should be safe.
        expect(Time.now - start_time).to be < 3
        expect(counter).to eq(0)
      end

    end

  end
end
