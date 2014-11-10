require "stud/task"
module Stud
  # This implementation tries to keep clock more accurately.
  # Prior implementations still permitted skew, where as this one
  # will attempt to correct for skew.
  #
  # The execution patterns of this method should be that
  # the start time of 'block.call' should always be at time T*interval
  def self.interval(time, opts = {}, &block)
    start = Time.now
    while true
      break if Task.interrupted?
      if opts[:sleep_then_run]
        start = sleep_for_interval(time, start)
        block.call
      else
        block.call
        start = sleep_for_interval(time, start)
      end
    end # loop forever
  end # def interval

  def self.sleep_for_interval(time, start)
    duration = Time.now - start
    # Sleep only if the duration was less than the time interval
    if duration < time
      sleep(time - duration)
      start += time
    else
      # Duration exceeded interval time, reset the clock and do not sleep.
      start = Time.now
    end
  end

  def interval(time, opts = {}, &block)
    return Stud.interval(time, opts, &block)
  end # def interval
end # module Stud
