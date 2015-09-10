require "thread"

module Stud
  class Task
    def initialize(*args, &block)
      # A queue to receive the result of the block
      # TODO(sissel): Don't use a queue, just store it in an instance variable.
      @queue = Queue.new

      @thread = Thread.new(@queue, *args) do |queue, *args|
        begin
          result = block.call(*args)
          queue << [:return, result]
        rescue => e
          queue << [:exception, e]
        end
      end # thread
    end # def initialize

    def wait
      @thread.join
      reason, result = @queue.pop

      if reason == :exception
        #raise StandardError.new(result)
        raise result
      else
        return result
      end
    end # def wait

    def stop!
      Thread.current[:stud_task_interrupted] = true
    end

    def self.interrupted?
      Thread.current[:stud_task_interrupted]
    end

    def wakeup
      @thread.wakeup
    end

    def status
      @thread.status
    end

  end # class Task
end # module Stud
