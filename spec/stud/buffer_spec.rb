require "stud/buffer"
require "stud/try"
require "spec_env" # from the top level spec/ directory
Thread.abort_on_exception = true

class BufferSubject
  include Stud::Buffer
  attr_accessor :buffer_state
  def initialize(options=nil)
    buffer_initialize(options) if options
  end
  def flush(items, group=nil); end
  def on_flush_error(exception); end
end

describe Stud::Buffer do

  it "should raise an error if included in a class which does not define flush" do
    class DoesntDefineFlush
      include Stud::Buffer
    end
    insist { DoesntDefineFlush.new.buffer_initialize }.raises ArgumentError
  end

  describe "buffer_full?" do
    it "should be false when when we have less than max_items" do
      subject = BufferSubject.new(:max_items => 2)
      subject.buffer_receive('one')

      insist { subject.buffer_full? } == false
    end

    it "should be true when we have more than max_items" do
      subject = BufferSubject.new(:max_items => 1)

      # take lock to prevent buffer_receive from flushing immediately
      subject.buffer_state[:flush_mutex].lock
      # so we'll accept this item, and not block, but won't flush it.
      subject.buffer_receive('one')

      insist { subject.buffer_full? } == true
    end
  end

  describe "buffer_receive" do

    it "should initialize buffer if necessary" do
      subject = BufferSubject.new
      insist { subject.buffer_state }.nil?

      subject.buffer_receive('item')

      insist { subject.buffer_state }.is_a?(Hash)
    end

    it "should block if max_items has been reached" do
      subject = BufferSubject.new(:max_interval => 2, :max_items => 5)

      # set up internal state so we're full.
      subject.buffer_state[:pending_count] = 5
      subject.buffer_state[:pending_items][nil] = [1,2,3,4,5]

      expect(subject).to receive(:flush).with([1,2,3,4,5], nil)

      start = Time.now
      subject.buffer_receive(6)

      # we were hung for max_interval, when the timer kicked in and cleared out some events
      insist { Time.now-start } > 2
    end

    it "should block while pending plus outgoing exceeds max_items" do
      subject = BufferSubject.new(:max_interval => 10, :max_items => 5)

      # flushes are slow this time.
      allow(subject).to receive(:flush) { sleep(4) }

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

      # if we waited this long, it had to be while we were blocked on the slow flush
      # this proves that outgoing items are counted when determining whether to block or not
      insist { Time.now - start } > 3.8
    end

    it "should call on_full_buffer_receive if defined when buffer is full" do
      class DefinesOnFullBufferReceive < BufferSubject
        attr_reader :full_buffer_notices
        def initialize(options=nil)
          super
          @full_buffer_notices = []
        end
        # we'll get a lot of calls to this method
        def on_full_buffer_receive(*args)
          @full_buffer_notices << args
        end
      end

      subject = DefinesOnFullBufferReceive.new(:max_items => 1)

      # start out with a full buffer
      subject.buffer_state[:pending_items][nil] = "waiting to flush"
      subject.buffer_state[:pending_count] = 1

      Thread.new do
        sleep 0.5
        subject.buffer_flush
      end

      # will block until the other thread calls buffer_flush
      subject.buffer_receive "will be blocked"

      insist { subject.full_buffer_notices.size } > 0
      subject.full_buffer_notices.each do |notice|
        insist { notice } == [{:pending => 1, :outgoing => 0}]
      end
    end

  end

  # these test both buffer_recieve and buffer_flush
  describe "buffer and flush behaviors" do
    it "should accept new items to pending list" do
      subject = BufferSubject.new(:max_items => 2)

      expect(subject).to receive(:flush).with(['something', 'something else'], nil)

      subject.buffer_receive('something')
      subject.buffer_receive('something else')
    end

    it "should accept optional grouping key" do
      subject = BufferSubject.new(:max_items => 2)

      # we get 2 flush calls, one for each key
      expect(subject).to receive(:flush).with(['something'], 'key1', nil)
      expect(subject).to receive(:flush).with(['something else'], 'key2', nil)

      subject.buffer_receive('something', 'key1')
      subject.buffer_receive('something else', 'key2')
    end

    it "should accept non-string grouping keys" do
      subject = BufferSubject.new(:max_items => 2)

      expect(subject).to receive(:flush).with(['something'], {:key => 1, :foo => :yes}, nil)
      expect(subject).to receive(:flush).with(['something else'], {:key => 2, :foo => :no}, nil)

      subject.buffer_receive('something', :key => 1, :foo => :yes)
      subject.buffer_receive('something else', :key => 2, :foo => :no)
    end
  end

  describe "buffer_flush" do

    it "should call on_flush_error and retry if an exception occurs" do
      subject = BufferSubject.new(:max_items => 1)
      error = RuntimeError.new("blah!")

      # first flush will raise an exception
      expect(subject).to receive(:flush).and_raise(error)
      # which will be passed to on_flush_error
      expect(subject).to receive(:on_flush_error).with(error)
      # then we'll retry and succeed. (w/o this we retry forever)
      expect(subject).to receive(:flush)

      subject.buffer_receive('item')
    end

    it "should retry if no on_flush_error is defined" do
      class DoesntDefineOnFlushError
        include Stud::Buffer
        def flush; end;
      end

      subject = DoesntDefineOnFlushError.new
      subject.buffer_initialize(:max_items => 1)

      # first flush will raise an exception
      expect(subject).to receive(:flush).and_raise("boom!")
      # then we'll retry and succeed. (w/o this we retry forever)
      expect(subject).to receive(:flush)

      subject.buffer_receive('item')
    end

    it "should return if it cannot get a lock" do
      subject = BufferSubject.new(:max_items => 1, :max_interval => 100)
      subject.buffer_state[:pending_items][nil] << 'message'
      subject.buffer_state[:pending_count] = 1
      subject.buffer_state[:flush_mutex].lock

      # we should have flushed a message (since :max_items has been reached),
      # but can't due to the lock.
      insist { subject.buffer_flush } == 0

      subject.buffer_state[:flush_mutex].unlock

      # and now we flush successfully
      insist { subject.buffer_flush } == 1
    end

    it "flushes when pending count is less than max items if forced" do
      subject = BufferSubject.new(:max_items => 5)
      subject.buffer_receive('one')
      subject.buffer_receive('two')
      subject.buffer_receive('three')

      insist { subject.buffer_flush(:force => true) } == 3
    end

    it "should block until lock can be acquired if final option is used" do
      subject = BufferSubject.new(:max_items => 2, :max_interval => 100)
      subject.buffer_receive 'message'

      lock_acquired = false
      Thread.new do
        subject.buffer_state[:flush_mutex].lock
        lock_acquired = true
        sleep 0.5
        subject.buffer_state[:flush_mutex].unlock
      end

      while (!lock_acquired) do end

      # we'll block for 0.5 seconds and then succeed in flushing our message
      insist { subject.buffer_flush(:final => true) } == 1
    end

    it "does not flush if no items are pending" do
      subject = BufferSubject.new(:max_items => 5)
      insist { subject.buffer_flush } == 0
    end

    it "does not flush if pending count is less than max items" do
      subject = BufferSubject.new(:max_items => 5)
      subject.buffer_receive('hi!')
      insist { subject.buffer_flush } == 0
    end

    it "flushes when time since last flush exceeds max_interval" do
      class AccumulatingBufferSubject < BufferSubject
        attr_reader :flushed
        def flush(items, final=false)
          @flushed = items
        end
      end

      subject = AccumulatingBufferSubject.new(:max_items => 5, :max_interval => 1)
      subject.buffer_receive('item!')

      Stud.try(10.times) do
        insist { subject.flushed } == ['item!']
      end
    end
  end
end
