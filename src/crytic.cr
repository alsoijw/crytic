require "option_parser"
require "./crytic/runner"

subject_source = ""
spec_files = [] of String

OptionParser.parse! do |parser|
  parser.banner = "Usage: crytic [arguments]"
  parser.on("-s SOURCE", "--subject=SOURCE", "Specifies the source file for the subject") do |source|
    subject_source = source
  end
  parser.on("-h", "--help", "Show this help") { puts parser }
  parser.unknown_args { |args| spec_files = args }
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

success = Crytic::Runner.new.run(subject_source, spec_files)

exit(success ? 0 : 1)
