require "stud/trap"
require "stud/try"
require "spec_env" # from the top level spec/ directory
require "timeout"

describe "Stud#trap" do

  it "should call multiple traps for a single signal" do
    queue = Queue.new
    Stud.trap("USR2") { queue << 1 }
    Stud.trap("USR2") { queue << 2 }
    Stud.trap("USR2") { queue << 3 }
    Process.kill("USR2", Process.pid)

    Stud.try(10.times) do
      insist { queue.size } == 3
    end

    insist { queue.pop } == 1
    insist { queue.pop } == 2
    insist { queue.pop } == 3
  end

  it "should keep any original traps set with Kernel#trap" do
    hupped = false
    studded = false

    queue = Queue.new
    # Set a standard signal using the ruby stdlib method
    Kernel.trap("HUP") { queue << :kernel }

    # This should still keep the previous trap.
    Stud.trap("HUP") { queue << :stud }

    # Send SIGHUP
    Process.kill("HUP", Process.pid)

    # Wait for both signal handlers to get called.
    Stud.try(10.times) do
      insist { queue.size } == 2
    end

    # Kernel handler should get called first since it was 
    # there first.
    insist { queue.pop } == :kernel

    # Our stud.trap should get called second
    insist { queue.pop } == :stud
  end
end
