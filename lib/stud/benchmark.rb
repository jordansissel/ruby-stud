# encoding: UTF-8
# Benchmark Use Cases
#   * Compare performance of different implementations.
#     * run each implementation N times, compare runtimes (histogram, etc)

require "metriks"
require "stud/benchmark/rusage"

module Stud
  module Benchmark
    def self.run(iterations=1, &block)
      timer = Metriks::Timer.new
      iterations.times { timer.time(&block) }
      return Results.new(timer)
    end # def run

    def self.runtimed(seconds=10, &block)
      timer = Metriks::Timer.new
      expiration = Time.now + seconds
      timer.time(&block) while Time.now < expiration
      return Results.new(timer)
    end # def runtimed

    def self.cputimed(seconds=10, &block)
      timer = Metriks::Timer.new
      expiration = Time.now + seconds
      while Time.now < expiration
        start = Stud::Benchmark::RUsage.get
        block.call
        finish = Stud::Benchmark::RUsage.get
        cputime = (finish.user + finish.system) - (start.user + start.system)
        timer.update(cputime)
      end # while not expired
      return Results.new(timer)
    end # self.cpu

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
        @data.snapshot.each(&block)
      end # def each

      def min
        return @data.min
      end

      def max
        return @data.max
      end

      def mean
        return @data.mean
      end # def mean

      def stddev
        # work around (Timer#stddev reports the variance)
        # https://github.com/eric/metriks/pull/29
        return @data.stddev ** 0.5
      end # def stddev

      def sum
        return @data.instance_eval { @histogram.sum }
      end # def sum

      def pretty_print
        puts self
      end # def pretty_print

      def to_s(scale=min .. max, ticks=10)
        snapshot = @data.snapshot
        values = snapshot.instance_eval { @values }
        scale_distance = scale.end - scale.begin
        tick = scale_distance / ticks
        dist = ticks.to_i.times.collect do |i|
          range = (scale.begin + tick * i) ... (scale.begin + tick * (i+1))
          hits = values.select { |v| range.include?(v) }.count
          percent = hits / values.size.to_f
          next TICKS[(TICKS.count * percent).ceil] || TICKS.last
        end

        return sprintf("%20s %s (%.4f ... %.4f, mean: %0.4f, stddev: %0.4f)",
                       environment, dist.join(""), scale.begin, scale.end,
                       mean, stddev)
      end # def to_s
    end # class Stud::Benchmark::Result
  end # module Benchmark
end # module Stud
