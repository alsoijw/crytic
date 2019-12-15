require "../../src/crytic/mutation/no_mutation"
require "../../src/crytic/runner/sequential"
require "../spec_helper"

module Crytic::Runner
  def self.subjects(paths)
    paths.map { |path| Subject.from_filepath(path) }
  end

  describe Sequential do
    describe "#run" do
      it "returns false if threshold ain't reached" do
        run = Run.new(
          msi_threshold: 100.0,
          reporters: [] of Crytic::Reporter::Reporter,
          subjects: subjects(["./fixtures/require_order/blog.cr", "./fixtures/require_order/pages/blog/archive.cr"]),
          spec_files: ["./fixtures/simple/bar_spec.cr"],
          generator: FakeGenerator.new,
          no_mutation_factory: fake_no_mutation_factory
        )

        Sequential.new.run(run, side_effects).should eq false
      end

      it "doesn't execute mutations if the initial suite run fails" do
        process_runner = Crytic::FakeProcessRunner.new
        process_runner.exit_code = [1, 0]
        run = Run.new(
          msi_threshold: 100.0,
          reporters: [] of Crytic::Reporter::Reporter,
          subjects: subjects(["./fixtures/require_order/blog.cr", "./fixtures/require_order/pages/blog/archive.cr"]),
          spec_files: ["./fixtures/simple/bar_spec.cr"],
          generator: FakeGenerator.new,
          no_mutation_factory: ->(specs : Array(String)) {
            no_mutation = Crytic::Mutation::NoMutation.with(specs)
            no_mutation
          }
        )

        Sequential.new.run(run, side_effects(process_runner: process_runner)).should eq false
      end

      it "reports events in order" do
        reporter = FakeReporter.new
        run = Run.new(
          msi_threshold: 100.0,
          reporters: [reporter] of Crytic::Reporter::Reporter,
          subjects: subjects(["./fixtures/simple/bar.cr"]),
          spec_files: ["./fixtures/simple/bar_spec.cr"],
          generator: FakeGenerator.new([fake_mutation]),
          no_mutation_factory: fake_no_mutation_factory
        )

        Sequential.new.run(run, side_effects)

        reporter.events.should eq ["report_original_result", "report_mutations", "report_neutral_result", "report_result", "report_summary", "report_msi"]
      end

      it "skips the mutations if the neutral result errored" do
        reporter = FakeReporter.new
        mutation = fake_mutation
        run = Run.new(
          msi_threshold: 100.0,
          reporters: [reporter] of Crytic::Reporter::Reporter,
          subjects: subjects(["./fixtures/simple/bar.cr"]),
          spec_files: ["./fixtures/simple/bar_spec.cr"],
          generator: FakeGenerator.new(
            neutral: erroring_mutation,
            mutations: [mutation]),
          no_mutation_factory: fake_no_mutation_factory
        )

        Sequential.new.run(run, side_effects)

        reporter.events.should_not contain("report_result")
        mutation.as(FakeMutation).run_call_count.should eq 0
      end
    end
  end
end
