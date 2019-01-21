require 'byebug'
require "benchmark"
require "ruby-prof"
require "json"

require_relative "tree"
require_relative "encoder"
require_relative "decoder"

table = {}
action = ARGV[0]
file_name = ARGV[1]
chunk_size = ARGV[2].to_i || 8

unless File.exists?(file_name)
  puts "Couldn't find file!"
  puts "Given path: #{file_name}"
  exit
end

unless chunk_size % 8 == 0
  chunk_size = 8
  puts "! Changing byte size to 8 !"
end

if action == ("-b")
  puts "Starting benchmark"
  puts "Using #{chunk_size} as byte size."
  puts
  puts "============"
  encoded_size = 0
  Benchmark.benchmark(Benchmark::CAPTION, 16, Benchmark::FORMAT, "Total:") do |x|
    puts ""
    ct = x.report("Creating Table: ") do
      table = Tree.create_table(file_name, chunk_size)
    end
    en = x.report("Encoding: ") do
      encoded_size = Encoder.encode(file_name, table, chunk_size)
    end
    de = x.report("Decoding:") do
      Decoder.decode(file_name)
    end
    puts ""

    [(ct + en + de)]
  end
  puts
  puts "Done! Compression ratio: " + ((1 - (encoded_size.to_f / File.size(file_name).to_f)) * 100).round(2).to_s + "%" + " (#{encoded_size}b / #{File.size(file_name)}b)"
  puts
  puts "============"
elsif action == ("-p")
  puts "Using ruby profiler:"

  puts "\n" + ("="*110)
  puts
  puts "Creating table..."
  result = RubyProf.profile do
    table = Tree.create_table(file_name, chunk_size)
  end
  RubyProf::GraphPrinter.new(result).print(STDOUT, {})

  puts "\n" + ("="*110)
  puts
  puts "Encoding..."
  result = RubyProf.profile do
    Encoder.encode(file_name, table, chunk_size)
  end
  RubyProf::GraphPrinter.new(result).print(STDOUT, {})

  puts "\n" + ("="*110)
  puts
  puts "Decoding..."
  result = RubyProf.profile do
    Decoder.decode(file_name)
  end
  RubyProf::GraphPrinter.new(result).print(STDOUT, {})
  puts "\n" + ("="*110)
  puts
else
  if action == "encode"
    puts "Encoding file: #{File.basename(file_name, ".*")}"
    encoded_size = Encoder.encode(file_name, Tree.create_table(file_name, chunk_size), chunk_size)
    puts "Done! Compression ratio: " + ((1 - (encoded_size.to_f / File.size(file_name).to_f)) * 100).round(2).to_s + "%"
  elsif action == "decode"
    puts "Decoding file: #{File.basename(file_name, ".*")}"
    Decoder.decode(file_name)
    puts "Done!"
  end
end