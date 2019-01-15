require "../src/crytic/mutant/and_or_swap"
require "../src/crytic/mutant/number_literal_change"
require "../src/crytic/subject"
require "./spec_helper"
require "compiler/crystal/syntax/*"

module Crytic
  describe Subject do
    describe "#original_source" do
      it "returns the original, but parsed source" do
        source = Subject.new(source: "puts \"hi\"", subject_file_path: "foo.cr")
        source.original_source.should eq "puts(\"hi\")"
      end
    end

    describe "#mutated_source" do
      it "returns the mutated source for transformer mutants" do
        mutant = Mutant::AndOrSwap.at(location_at(
          line_number: 1,
          column_number: 1))

        source = Subject.new(source: "1 && 2", subject_file_path: "foo.cr")
        source.mutate_source!(mutant).should eq "1 || 2"
        source.mutated_source.should eq "1 || 2"
      end

      it "returns the mutated source code for visitor mutants" do
        mutant = Mutant::NumberLiteralChange.at(location_at(
          line_number: 1,
          column_number: 1))

        source = Subject.new(source: "1", subject_file_path: "foo.cr")
        source.mutate_source!(mutant).should eq "0"
        source.mutated_source.should eq "0"
      end
    end

    it "proxies the filename to the parser" do
      source = Subject.new(source: "1", subject_file_path: "some_file.cr")
      visitor = FakeVisitor.new

      source.mutate_source!(visitor)

      visitor.last_location.to_s.should eq "some_file.cr:1:1"
    end
  end

  class FakeVisitor < Crystal::Visitor
    getter! last_location
    @last_location : Crystal::Location?

    def visit(node : Crystal::ASTNode)
      @last_location = node.location
      true
    end
  end
end
