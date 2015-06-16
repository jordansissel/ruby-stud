require "stud/try"
require "spec_env" # from the top level spec/ directory

class FakeFailure < StandardError; end
class DummyException < Exception; end
class OtherException < Exception; end
class RetryableException < Exception; end

describe Stud::Try do
  class FastTry < Stud::Try
    def failure(*args)
      # do nothing
    end
  end # class FastTry

  subject { FastTry.new }

  it "should give up after N tries when given 'N.times'" do
    count = 0
    total = 5

    # This 'try' should always fail.
    insist do
      subject.try(total.times) do
        count += 1
        raise Insist::Failure, "intentional"
      end 
    end.fails

    # But it should try 'total' times.
    insist { count } == total
  end

  it "should pass the current iteration value to the block" do
    count = 0
    total = 5

    # This 'try' should always fail.
    values = total.times.to_a
    insist do
      subject.try(total.times) do |value|
        count += 1
        insist { value } == values.shift
        raise FakeFailure, "intentional"
      end 
    end.raises(FakeFailure)
    # But it should try 'total' times.
    insist { count } == total
  end

  it "should appear to try forever by default" do
    # This is really the 'halting problem' but if we 
    # try enough times, consider that it is likely to continue forever.
    count = 0
    value = subject.try do
      count += 1
      raise FakeFailure if count < 1000
    end
    insist { count } == 1000
  end

  it "should return the block return value on success" do
    insist { subject.try(1.times) { 42 } } == 42
  end

  it "should raise the last exception on final failure" do
    insist do
      subject.try(1.times) { raise FakeFailure } 
    end.raises(FakeFailure)
  end

  it "should expose a default try as Stud.try" do
    # Replace the log method with a noop.
    class << Stud::TRY ; def log_failure(*args) ; end ; end

    insist do
      Stud.try(3.times) { raise FakeFailure }
    end.raises(FakeFailure)
  end

  context "when specifying exceptions" do
    let(:total) { 5 }

    it "allows to specify retryable exceptions" do
      count = 0
      insist do
        Stud.try(total.times, DummyException) do
          count += 1
          raise DummyException
        end
      end.raises(DummyException)

      insist { count } == total
    end

    it "You can specify a list" do
      count = 0

      insist do
        Stud.try(total.times, [DummyException, RetryableException]) do
          count += 1
          if count < 2
            raise DummyException
          else
            raise RetryableException
          end
        end
      end.raises(RetryableException)

      insist { count } == total
    end

    it "doesnt retry if the exception is not in the list" do
      count = 0
      insist do
        Stud.try(total.times, DummyException) do
          count += 1
          raise RetryableException
        end
      end.raises(RetryableException)

      insist { count } == 1
    end
  end
end
