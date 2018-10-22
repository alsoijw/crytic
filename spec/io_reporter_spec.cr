require "../src/crytic/io_reporter"
require "../src/crytic/mutant/number_literal_change"
require "../src/crytic/mutation/original_result"
require "spec"

private def fake_mutant
  Crytic::Mutant::NumberLiteralChange.at(Crystal::Location.new(filename: nil, line_number: 0, column_number: 0))
end

private def original(exit_code = 0, output = "output")
  Crytic::Mutation::OriginalResult.new(exit_code: exit_code, output: output)
end

module Crytic
  describe IoReporter do
    describe "#report_original_result" do
      it "prints the original passing suites status" do
        io = IO::Memory.new
        IoReporter.new(io).report_original_result(original)
        io.to_s.should contain("✅ Original test suite passed.\n")
      end

      it "prints the original suites failing status" do
        io = IO::Memory.new
        IoReporter.new(io).report_original_result(original(1, "failed!!!"))
        io.to_s.should contain("❌ Original test suite failed.")
        io.to_s.should contain("failed!!!")
      end
    end

    describe "#report_result" do
      it "prints the passing mutants name and location" do
        io = IO::Memory.new
        result = Mutation::Result.new(
          is_covered: true,
          did_error: false,
          mutant: fake_mutant,
          diff: "")
        IoReporter.new(io).report_result(result)
        io.to_s.should contain("✅ NumberLiteralChange at line 0, column 0")
      end

      it "prints failing mutants name" do
        io = IO::Memory.new
        result = Mutation::Result.new(is_covered: false, did_error: false, mutant: fake_mutant, diff: "diff")
        IoReporter.new(io).report_result(result)
        io.to_s.should contain("❌ NumberLiteralChange")
        io.to_s.should contain("diff")
        io.to_s.should_not contain("nope")
      end

      it "prints errored mutant" do
        io = IO::Memory.new
        result = Mutation::Result.new(is_covered: false, did_error: true, mutant: fake_mutant, diff: "diff")
        IoReporter.new(io).report_result(result)
        io.to_s.should contain("❌ NumberLiteralChange")
        io.to_s.should contain("The following change broke the code")
        io.to_s.should contain("diff")
      end
    end
    describe "#report_summary" do
      it "outputs result counts with a score" do
        io = IO::Memory.new
        results = [
          Mutation::Result.new(is_covered: false, did_error: false, mutant: fake_mutant, diff: "diff"),
          Mutation::Result.new(is_covered: true, did_error: false, mutant: fake_mutant, diff: "diff"),
          Mutation::Result.new(is_covered: false, did_error: true, mutant: fake_mutant, diff: "diff"),
        ]
        IoReporter.new(io).report_summary(results)
        io.to_s.should contain "Finished in"
        io.to_s.should contain "3 mutations, 1 covered, 1 uncovered, 1 errored. Mutation score: 33.33%"
      end
    end
  end
end
