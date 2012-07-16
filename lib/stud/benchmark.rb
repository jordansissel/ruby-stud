# encoding: UTF-8
# Benchmark Use Cases
#   * Compare performance of different implementations.
#     * run each implementation N times, compare runtimes (histogram, etc)

module Stud
  module Benchmark
    def self.run(iterations=1, &block)
      i = 0
      data = []
      full_start = Time.now
      while i < iterations
        start = Time.now
        block.call
        duration = Time.now - start
        data << duration
        i += 1
      end
      return Results.new(data)
    end # def run

    class Results
      include Enumerable
      # Stolen from https://github.com/holman/spark/blob/master/spark
      TICKS = %w{▁ ▂ ▃ ▄ ▅ ▆ ▇ █}

      def initialize(data)
        @data = data
      end # def initialize

      def environment
        # Older rubies don't have the RUBY_ENGINE defiend
        engine = (RUBY_ENGINE rescue "ruby")
        # Include jruby version in the engine
        engine += (JRUBY_VERSION rescue "")
        version = RUBY_VERSION

        return "#{engine} #{version}"
      end # def environment

      def each(&block)
        @data.each(&block)
      end # def each

      def log_distribution
        return distribution do |value|
          if value == 0
            0 ... 0
          else
            tick = (Math.log2(value).floor).to_f rescue 0
            (2 ** tick) ... (2 ** (tick+1))
          end
        end
      end # def log_distribution

      def distribution(&range_compute)
        raise ArgumentError.new("Missing range computation block") if !block_given?

        max = @data.max
        dist = Hash.new { |h,k| h[k] = 0 }
        each do |value| 
          range = range_compute.call(value)
          dist[range] += 1
        end
        return dist
      end # def distribution

      def mean
        if @mean.nil?
          total = Float(@data.count)
          @mean = sum / total
        end
        return @mean
      end # def mean

      def stddev
        # sum of square deviations of mean divided by total values
        return Math.sqrt(inject(0) { |s, v| s + (v - mean) ** 2 } / (@data.count - 1))
      end # def stddev

      def sum
        if @sum.nil?
          @sum = inject(0) { |s,v| s + v }
        end
        return @sum
      end # def sum

      def to_s
        return "#{environment}: avg: #{mean} stddev: #{stddev}"
      end # def to_s

      def pretty_print
        min = @data.min
        max = @data.max
        zmax = Float(max - min) # "zero" at the 'min' value, offset the max.
        incr = 0.1 # 10% increments
        #dist = distribution do |value|
          #percent = (value - min) / zmax
          #if percent == 1
            #(1 - incr ... 1.0)
          #else
            #start = ((percent * 10).floor / 10.0)
            #start ... (start + incr)
          #end
        #end
        dist = log_distribution

        total = dist.inject(0) { |sum, (step, count)| sum + count }
        sorted = dist.sort { |a,b| a.first.begin <=> b.first.begin }
        puts sorted.collect { |lower_bound, count|
          #puts lower_bound
          percent = (count / Float(total))
          "%30s: %s" % [lower_bound, (TICKS.last * (50 * percent).ceil)]
        }.join("\n")

      end # def pretty_print
    end # class Stud::Benchmark::Result
  end # module Benchmark
end # module Stud

#require "thread"
#mutex = Mutex.new
#results = Stud::Benchmark.run(20) { mutex.synchronize { rand; rand; rand } }
#results.pretty_print
