require "securerandom" # for uuid generation
require "fileutils"

module Stud
  module Temporary
    # Returns a string for a randomly-generated temporary path.
    #
    # This does not create any files.
    def pathname(prefix="")
      root = ENV["TMP"] || ENV["TMPDIR"] || ENV["TEMP"] || "/tmp"
      return File.join(root, "#{prefix}-#{SecureRandom.uuid}")
    end

    # Return a File handle to a randomly-generated path.
    #
    # Any arguments beyond the first (prefix) argument will be
    # given to File.new.
    #
    # If no file args are given, the default file mode is "w+"
    def file(prefix="", *args, &block)
      args << "w+" if args.empty?
      return File.new(pathname(prefix), *args)
    end

    # Make a temporary directory.
    #
    # If given a block, the directory path is given to the block.  WHen the
    # block finishes, the directory and all its contents will be deleted.
    #
    # If no block given, it will return the path to a newly created directory.
    # You are responsible for then cleaning up.
    def directory(prefix="", &block)
      path = pathname(prefix)
      Dir.mkdir(path)

      if block_given?
        block.call(path)
        FileUtils.rm_r(path)
      else
        return path
      end
    end
  end # module Temporary

  extend self
end # module Stud

