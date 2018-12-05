require "./generator"
require "./io_reporter"
require "./msi_calculator"
require "./mutant/**"
require "./mutation/mutation"
require "./mutation/no_mutation"
require "./source"

module Crytic
  class Runner
    alias Threshold = Float64

    def initialize(@threshold : Threshold = 100.0, @reporters = [IoReporter.new(STDOUT)])
    end

    def run(source : String, specs : Array(String)) : Bool
      validate_args!(source, specs)

      original_result = Mutation::NoMutation
        .with(specs: specs)
        .run

      @reporters.each { |reporter| reporter.report_original_result(original_result) }

      return false unless original_result.successful?

      results = Generator
        .new
        .mutations_for(source: source, specs: specs)
        .map do |mutation|
          result = mutation.run
          @reporters.each { |reporter| reporter.report_result(result) }
          result
        end

      @reporters.each { |reporter| reporter.report_summary(results) }

      return MsiCalculator.new(results).passes?(@threshold)
    end

    private def validate_args!(source, specs)
      if specs.empty?
        raise ArgumentError.new("No spec files given.")
      end

      unless File.exists?(source)
        raise ArgumentError.new("Source file for subject doesn't exist.")
      end

      specs.each do |spec_file|
        unless File.exists?(spec_file)
          raise ArgumentError.new("Spec file #{spec_file} doesn't exist.")
        end
      end
    end
  end
end
