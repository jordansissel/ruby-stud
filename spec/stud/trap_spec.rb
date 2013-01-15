require "stud/trap"
require "spec_env" # from the top level spec/ directory

class FakeFailure < StandardError; end

describe "Stud#trap" do
  it "should call multiple traps for a single signal" do
    count = 0
    Stud.trap("USR1") { puts "USR1"; count += 1 }
    Stud.trap("USR1") { puts "USR2"; count += 2 }
    Stud.trap("USR1") { puts "USR3"; count += 3 }
    Process.kill("USR1", Process.pid)
    sleep(0.5)
    insist { count } == 6
  end

  it "should keep any original traps set with Kernel#trap" do
    hupped = false
    studded = false
    Kernel.trap("HUP") { hupped = true }
    Stud.trap("HUP") { studded = true }
    Process.kill("HUP", Process.pid)
    insist { hupped } == true
    insist { studded } == true
  end

  it "should override" do
    hupped = false
    studded = false
    Kernel.trap("HUP") { hupped = true }
    Stud.trap("HUP") { studded = true }
    Process.kill("HUP", Process.pid)
    insist { hupped } == true
    insist { studded } == true
  end
end
