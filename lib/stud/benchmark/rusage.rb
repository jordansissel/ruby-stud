require "ffi"

module Stud
  module Benchmark
    module LibC
      extend FFI::Library
      ffi_lib "libc.so.6"

      attach_function :getrusage, [:int, :pointer], :int
    end

    class TimeVal < FFI::Struct
      layout :tv_sec, :long,
             :tv_usec, :int32

      def to_f
        return self[:tv_sec] + (self[:tv_usec] / 1_000_000.0)
      end
    end

    class RUsage < FFI::Struct
      layout :utime, TimeVal,
             :stime, TimeVal,
             :maxrss, :long,
             :ixrss, :long,
             :idrss, :long,
             :isrss, :long,
             :minflt, :long,
             :majflt, :long,
             :nswap, :long,
             :inblock, :long,
             :oublock, :long,
             :msgsnd, :long,
             :msgrcv, :long,
             :nsignals, :long,
             :nvcsw, :long,
             :nivcsw, :long

      def self.get
        usage = RUsage.new
        LibC.getrusage(0, usage)
        return usage
      end

      def user
        return self[:utime].to_f
      end

      def system
        return self[:stime].to_f
      end
    end # class RUsage
  end # module Benchmark
end # module Stud
