module Stud
  class Supervisor
    def initialize(*args, &block)
      @args = args
      @block = block

      run
    end # def initialize

    def run
      while true
        task = Task.new(*@args, &@block)
        begin
          puts :result => task.wait
        rescue => e
          puts e
          puts e.backtrace
        end
      end
    end # def run
  end # class Supervisor

  def self.supervise(&block)
    Supervisor.new(&block)
  end # def supervise
end # module Stud
