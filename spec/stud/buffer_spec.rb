require "stud/buffer"
require "spec_env" # from the top level spec/ directory

class BufferSubject
  include Stud::Buffer
  attr_accessor :buffer_state
  def flush; end;
end

class DoesntDefineFlush
  include Stud::Buffer
end


describe Stud::Buffer do

  it "should raise an error if included in a class which does not define flush" do
    insist { DoesntDefineFlush.new.buffer_initialize }.raises ArgumentError
  end

  describe "buffer_full?" do
    it "should be false when few items have been accumulated"
    it "should be true when enough items have been accumulated"
  end

  describe "buffer_receive" do

    it "should initialize buffer if necessary" do
      subject = BufferSubject.new
      insist { subject.buffer_state }.nil?

      subject.buffer_receive('item')

      insist { subject.buffer_state }.is_a?(Hash)
    end


    it "should accept new items to pending list" do
      subject = BufferSubject.new
      subject.buffer_receive('something')
      subject.buffer_receive('something else')

      subject.should_receive(:flush).with(['something', 'something else'])

      subject.buffer_flush(:force => true)
    end

    it "should accept optional grouping key" do
      subject = BufferSubject.new
      subject.buffer_receive('something', 'key1')
      subject.buffer_receive('something else', 'key2')

      subject.should_receive(:flush).with(['something'], 'key1')
      subject.should_receive(:flush).with(['something else'], 'key2')

      subject.buffer_flush(:force => true)
    end

    it "should accept non-string grouping keys" do
      subject = BufferSubject.new
      subject.buffer_receive('something', :key => 1, :foo => :yes)
      subject.buffer_receive('something else', :key => 2, :foo => :no)

      subject.should_receive(:flush).with(['something'], {:key => 1, :foo => :yes})
      subject.should_receive(:flush).with(['something else'], {:key => 2, :foo => :no})

      subject.buffer_flush(:force => true)
    end

    it "should block if max_items has been reached" do
      subject = BufferSubject.new
      subject.buffer_initialize(:max_interval => 2, :max_items => 5)

      # set up internal state so we're full.
      subject.buffer_state[:pending_count] = 5
      subject.buffer_state[:pending_items][nil] = [1,2,3,4,5]

      subject.should_receive(:flush).with([1,2,3,4,5])

      start = Time.now
      subject.buffer_receive(6)

      # we were hung for max_interval, when the timer kicked in and cleared out some events
      insist { Time.now-start } > 2
    end

    it "should block while pending plus outgoing exceeds max_items" do
      subject = BufferSubject.new
      subject.buffer_initialize(:max_interval => 10, :max_items => 5)

      # flushes are slow this time.
      subject.stub(:flush) { sleep 4 }

      subject.buffer_receive(1)
      subject.buffer_receive(2)
      subject.buffer_receive(3)

      thread_started = false

      Thread.new do
        thread_started = true
        # this will take 4 seconds to complete
        subject.buffer_flush(:force => true)
      end

      # best effort at ensuring batch_flush is underway
      # we want the inital 3 items to move from pending to outgoing before
      # we proceed
      while (!thread_started) do end
      sleep 0.1

      # now we accept 2 more events into pending
      subject.buffer_receive(4)
      subject.buffer_receive(5)

      # now we're full
      insist { subject.buffer_full? } == true

      # more buffer_receive calls should block until the slow
      # flush completes and decrements the number of outgoing items
      start = Time.now
      subject.buffer_receive(6)

      # if we waited this long, it had to be while we were blocked on SlowBufferSubject.flush
      # this proves that outgoing items are counted when determining whether to block or not
      insist { Time.now - start } > 3.8
    end
  end

  describe "buffer_flush" do
    it "should return if it cannot get a lock"
    it "should block until lock can be acquired if final option is used"
    it "should copy pending items to outgoing items and clear pending"
    it "should call flush with each group of outgoing items"
    it "should call on_flush_error if an exception occurs"
    it "should retry when exception occurs"
    it "should retry if no on_flush_error is defined"
    it "does not flush if no items are pending"
    it "normally does not flush if pending count is less than max items"
    it "flushes when pending count is less than max items if forced"
    it "flushes when time since last flush exceeds max_interval"
  end
end
