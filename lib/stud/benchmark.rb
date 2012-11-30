# encoding: UTF-8
# Benchmark Use Cases
#   * Compare performance of different implementations.
#     * run each implementation N times, compare runtimes (histogram, etc)

module Stud
  module Benchmark
    def self.run(iterations=1, &block)
      data = []

      iterations.times { data << time(&block) }
      return Results.new(data)
    end # def run

    def self.time(&block)
      start = Time.now
      block.call
      return Time.now - start
    end # def time

    def self.runtimed(seconds=10, &block)
      data = []
      expiration = Time.now + seconds
      data << time(&block) while Time.now < expiration
      return Results.new(data)
    end # def run

    class Results
      include Enumerable
      # Stolen from https://github.com/holman/spark/blob/master/spark
      # TICKS = %w{▁ ▂ ▃ ▄ ▅ ▆ ▇ █}

      TICKS = ["\x1b[38;5;#{232 + 8}m_\x1b[0m"] + %w{▁ ▂ ▃ ▄ ▅ ▆ ▇ █}

      #.collect do |tick|
        # 256 color support, use grayscale
        #1.times.collect do |shade|
          # '38' is foreground
          # '48' is background
          # Grey colors start at 232, but let's use the brighter half.
          # escape [ 38 ; 5 ; <color>
          #"\x1b[38;5;#{232 + 12 + 2 * shade}m#{tick}\x1b[0m"
        #end
        #tick
      #end.flatten

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

      def log_distribution(min=nil, max=nil)
        min ||= @data.min
        max ||= @data.max

        logrange = lambda do |value|
          if value == 0
            return 0 ... 0
          else
            tick = (Math.log2(value).floor).to_f rescue 0
            return (2 ** tick) ... (2 ** (tick+1))
          end
        end
        # Populate the distribution with real data and return it.
        return distribution(&logrange)
      end # def log_distribution

      def zeroed_log_distribution(min=nil, max=nil)
        min ||= @data.min
        max ||= @data.max

        logrange = lambda do |value|
          if value == 0
            return 0 ... 0
          else
            tick = (Math.log2(value - min).floor).to_f rescue 0
            return (min + 2 ** tick) ... (min + 2 ** (tick+1))
          end
        end
        # Populate the distribution with real data and return it.
        return distribution(&logrange)
      end # def log_distribution

      def tick_distribution(min=0.0, max=1.0, ticks=10)
        tick_size = (max - min) / ticks.to_f
        tickrange = lambda do |value|
          tick = ((value - min) / tick_size).floor * tick_size
          return (tick ... tick+tick_size)
        end

        # Fill in zero values for all possible ranges
        dist = {}
        (ticks+1).times do |i|
          dist[tickrange.call(i * tick_size)] = 0
        end

        return dist.merge(distribution(&tickrange))
      end # def tick_distribution

      def distribution(min=nil, max=nil, &range_compute)
        raise ArgumentError.new("Missing range computation block") if !block_given?
        min = @data.min if min.nil?
        max = @data.max if max.nil?
        dist = Hash.new { |h, k| h[k] = 0 }

        each do |value| 
          next if value > max || value < min
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

      def pretty_print
        puts to_s
      end

      def to_s(min=nil, max=nil)
        min = 0 if min.nil?
        max = @data.max if max.nil?
        builder = []
        incr = 0.1 # 10% increments

        #builder << "Total: #{sum} - Mean: #{mean}"
        #builder << "Environment: #{environment}"

        total = sum

        range_sort = proc { |a,b|  a.first.begin <=> b.first.begin }

        dist = tick_distribution(0, max, 30).sort(&range_sort).collect do |range, count|
          percent = (count / Float(@data.size))
          TICKS[(TICKS.count * percent).ceil] || TICKS.last
        end

        return sprintf("%20s %s (%.4f ... %.4f, mean: %0.4f, stddev: %0.4f)", environment, dist.join(""),
                       min, max, mean, stddev)
      end # def to_s
    end # class Stud::Benchmark::Result
  end # module Benchmark
end # module Stud
