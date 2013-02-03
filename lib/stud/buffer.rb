module Stud
  module Buffer

    def buffer_initialize(options={})
      if ! self.class.method_defined?(:flush)
        raise ArgumentError, "Any class including Stud::Buffer must define a flush() method."
      end

      @buffer_config = {
        :max_items => options[:max_items] || 50,
        :max_interval => options[:max_interval] || 5,
        :logger => options[:logger] || nil,
        :has_on_flush_error => self.class.method_defined?(:on_flush_error),
        :has_on_full_buffer_receive => self.class.method_defined?(:on_full_buffer_receive)
      }
      @buffer_state = {
        # items accepted from including class
        :pending_items => {},
        :pending_count => 0,

        # guard access to pending_items & pending_count
        :pending_mutex => Mutex.new,

        # items which are currently being flushed
        :outgoing_items => {},
        :outgoing_count => 0,

        # ensure only 1 flush is operating at once
        :flush_mutex => Mutex.new,

        # data for timed flushes
        :last_flush => Time.now.to_i,
        :timer => Thread.new do
          loop do
            sleep(@buffer_config[:max_interval])
            buffer_flush(:force => true)
          end
        end
      }

      # events we've accumulated
      buffer_clear_pending
    end

    def buffer_clear_pending
      @buffer_state[:pending_items] = Hash.new { |h, k| h[k] = [] }
      @buffer_state[:pending_count] = 0
    end

    def buffer_full?
      @buffer_state[:pending_count] + @buffer_state[:outgoing_count] >= @buffer_config[:max_items]
    end

    # save an event for later delivery
    # events are grouped by the (optional) group parameter you provide
    # groups of events, plus the group name, are passed to your batch_flush() method
    def buffer_receive(event, group=nil)
      buffer_initialize if ! @buffer_state

      # block if we've accumulated too many events
      while buffer_full? do
        on_full_buffer_receive(
          :pending => @buffer_state[:pending_count],
          :outgoing => @buffer_state[:outgoing_count]
        ) if @buffer_config[:has_on_full_buffer_receive]
        sleep 0.1
      end

      @buffer_state[:pending_mutex].synchronize do
        @buffer_state[:pending_items][group] << event
        @buffer_state[:pending_count] += 1
      end

      buffer_flush
    end

    # try to flush events
    # return immediately if we fail to get lock (another flush is in progress)
    #   unless called with :final => true. In that case, wait for a lock.
    # returns the number of items flushed successfully
    def buffer_flush(options={})
      force = options[:force] || options[:final]
      final = options[:final]

      # final flush will wait for lock, so we are sure to flush out all buffered events
      if options[:final]
        @buffer_state[:flush_mutex].lock
      elsif ! @buffer_state[:flush_mutex].try_lock # failed to get lock, another flush already in progress
        return 0
      end

      begin
        time_since_last_flush = Time.now.to_i - @buffer_state[:last_flush]

        return 0 if @buffer_state[:pending_count] == 0
        return 0 if (!force) &&
           (@buffer_state[:pending_count] < @buffer_config[:max_items]) &&
           (time_since_last_flush < @buffer_config[:max_interval])

        @buffer_state[:pending_mutex].synchronize do
          @buffer_state[:outgoing_items] = @buffer_state[:pending_items]
          @buffer_state[:outgoing_count] = @buffer_state[:pending_count]
          buffer_clear_pending
        end

        @buffer_config[:logger].debug("Flushing output",
          :outgoing_count => @buffer_state[:outgoing_count],
          :time_since_last_flush => time_since_last_flush,
          :outgoing_events => @buffer_state[:outgoing_items],
          :batch_timeout => @buffer_config[:max_interval],
          :force => force,
          :final => final
        ) if @buffer_config[:logger]

        items_flushed = 0
        @buffer_state[:outgoing_items].each do |group, events|
          begin
            if group.nil?
              flush(events)
            else
              flush(events, group)
            end

            @buffer_state[:outgoing_items].delete(group)
            events_size = events.size
            @buffer_state[:outgoing_count] -= events_size
            items_flushed += events_size

          rescue => e
            raise e
            @buffer_config[:logger].warn("Failed to flush outgoing items",
              :outgoing_count => @buffer_state[:outgoing_count],
              :exception => e,
              :backtrace => e.backtrace
            ) if @buffer_config[:logger]

            if @buffer_config[:has_on_flush_error]
              on_flush_error e
            end

            sleep 1
            retry
          end
          @buffer_state[:last_flush] = Time.now.to_i
        end

      ensure
        @buffer_state[:flush_mutex].unlock
      end

      items_flushed
    end
  end
end
