require "stud/try"
require "spec_env" # from the top level spec/ directory

describe "Stud::try" do
  context "try with enumerable" do
    it "should give up after N tries when given 'N.times'" do
      count = 0
      total = 5

      # This 'try' should always fail.
      insist do
        Stud::try(total.times) do
          count += 1
          raise Insist::Failure, "intentional"
        end 
      end.fails

      # But it should try 'total' times.
      insist { count } == total
    end

    it "should pass the current iteration value to the block" do
      count = 0
      total = 5

      # This 'try' should always fail.
      insist do
        Stud::try(total.times) do |value|
          count += 1
          insist { value }.is_a?(Numeric)
          raise Insist::Failure, "intentional"
        end 
      end.fails
      # But it should try 'total' times.
      insist { count } == total
    end

    it "should return the block return value on success" do
      insist { Stud::try { 42 } } == 42
    end
  end
end
