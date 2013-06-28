require "stud/with"
require "spec_env" # from the top level spec/ directory

describe Stud::With do
  include Stud::With # make these methods available in scope

  it "should work" do # ☺
    count = 0
    with("hello world") do |v|
      count += 1
      insist { v } == "hello world"
    end

    # Make sure the block is called.
    insist { count } == 1
  end
end
