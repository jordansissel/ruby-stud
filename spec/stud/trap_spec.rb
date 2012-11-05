require "stud/trap"
require "spec_env" # from the top level spec/ directory

class FakeFailure < StandardError; end

describe "Stud#trap" do
  it "should call multiple traps for a single signal" do
    count = 0
    Stud.trap("INT") { count += 1 }
    Stud.trap("INT") { count += 2 }
    Stud.trap("INT") { count += 3 }
    Process.kill("INT", Process.pid)
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
