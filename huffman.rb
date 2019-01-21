require 'byebug'
require "benchmark"
require "ruby-prof"

require_relative "tree"
require_relative "encoder"
require_relative "decoder"

table = {}
chunk_size = 16

if ARGV.include?("-b")
  puts "============"
  Benchmark.benchmark(Benchmark::CAPTION, 16, Benchmark::FORMAT, "Total:") do |x|
    puts ""
    ct = x.report("Creating Table: ") do
      table = Tree.create_table(ARGV[0], chunk_size)
    end
    en = x.report("Encoding: ") do
      Encoder.encode(ARGV[0], table, chunk_size)
    end
    de = x.report("Decoding:") do
      Decoder.decode(ARGV[0], table)
    end
    puts ""

    [(ct + en + de)]
  end
  puts "============"
elsif ARGV.include?("-p")
  puts "Using ruby profiler:"

  puts "\n" + ("="*110)
  puts
  puts "Creating table..."
  result = RubyProf.profile do
    table = Tree.create_table(ARGV[0], chunk_size)
  end
  RubyProf::GraphPrinter.new(result).print(STDOUT, {})

  puts "\n" + ("="*110)
  puts
  puts "Encoding..."
  result = RubyProf.profile do
    Encoder.encode(ARGV[0], table, chunk_size)
  end
  RubyProf::GraphPrinter.new(result).print(STDOUT, {})

  puts "\n" + ("="*110)
  puts
  puts "Decoding..."
  result = RubyProf.profile do
    Decoder.decode(ARGV[0], table)
  end
  RubyProf::GraphPrinter.new(result).print(STDOUT, {})
  puts "\n" + ("="*110)
  puts
else
  table = Tree.create_table(ARGV[0], chunk_size)
  Encoder.encode(ARGV[0], table, chunk_size)
  Decoder.decode(ARGV[0], table)
end