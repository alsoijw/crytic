require "../../src/crytic/mutation/result_set"
require "../spec_helper"

module Crytic::Mutation
  describe ResultSet do
    describe "#all_covered?" do
      it "returns true if all the results are covered" do
        ResultSet.new([
          result(Status::Covered),
          result(Status::Covered),
        ]).all_covered?.should eq true
      end

      it "returns false if any of the results isn't covered" do
        ResultSet.new([
          result(Status::Errored),
          result(Status::Covered),
        ]).all_covered?.should eq false
      end
    end
  end
end
