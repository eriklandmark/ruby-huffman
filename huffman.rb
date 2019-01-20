require 'byebug'
require "benchmark"
require "ruby-prof"

class Node
  attr_accessor :left, :right, :byte, :frequency

  def initialize(byte, freq)
    @left = nil
    @right = nil
    @byte = byte
    @frequency = freq
  end
end

class Tree

  def self.build(data, chunk_size)
    chunk_map = {}
    index = 0
    while index < data.length
      chunk = data[index...index + chunk_size]
      chunk_map[chunk] = {
          count: chunk_map[chunk] ? chunk_map[chunk][:count] += 1 : 1,
          taken: false
      }
      index += chunk_size
    end

    {chunks: chunk_map.keys, tree: tree(chunk_map.sort_by { |k,v | v[:count]})}
  end

  def self.create_table(file, chunk_size)
    data = File.binread(file).unpack("B*")[0]
    tree = self.build(data, chunk_size)
    paths = {}
    tree[:chunks].each do |chunk|
      r_get_paths(tree[:tree].left, chunk, paths)
      r_get_paths(tree[:tree].right, chunk, paths)
    end
    paths
  end

  private

  def self.tree(chunks)
    tree = Node.new("", 0)
    r_tree(chunks, tree, 1, Math.log2(chunks.length).ceil)
    tree
  end

  def self.r_tree(sorted_chunks, node, layer, max_layer)
    if layer <= max_layer
      nodes_left = sorted_chunks.count {|x| !x[1][:taken]}
      if nodes_left >= 2
        node.left = Node.new("", 0)
        r_tree(sorted_chunks, node.left, layer + 1, max_layer)
        node.right = Node.new("", 0)
        r_tree(sorted_chunks, node.right, layer + 1, max_layer)
      elsif nodes_left == 1
        new_node = sorted_chunks.find {|chunk| !chunk[1][:taken]}
        new_node[1][:taken] = true
        node.byte = new_node[0]
        node.frequency = new_node[1][:count]
      end
    else
      new_node = sorted_chunks.find {|chunk| !chunk[1][:taken]}
      if new_node
        new_node[1][:taken] = true
        node.left = Node.new(new_node[0], new_node[1][:count])
      end
      new_node = sorted_chunks.find {|chunk| !chunk[1][:taken]}
      if new_node
        new_node[1][:taken] = true
        node.right = Node.new(new_node[0], new_node[1][:count])
      end
    end
  end

  def self.r_get_paths(node, target, paths, path = nil)
    if node.byte == target
      paths[target] = path
    else
      if node.left
        r_get_paths(node.left, target, paths, path ? path + "0": "0")
      end
      if node.right
        r_get_paths(node.right, target, paths, path ? path + "1": "1")
      end
    end
  end

end

class Encoder
  def self.encode(file, table, chunk_size)
    data = File.binread(file).unpack("B*")[0]

    chunks = []
    index = 0
    while index < data.length
      chunks << table[data[index...index + chunk_size]]
      index += chunk_size
    end

    index = 0
    bytes = []
    unwritten_bytes = chunks.join("")
    if unwritten_bytes.length % 8 != 0
      unwritten_bytes += "0"*(8 - (unwritten_bytes.length % 8))
    end

    while index < unwritten_bytes.length
      bytes << unwritten_bytes[index...index + 8].to_i(2)
      index += 8
    end

    File.binwrite(File.basename(file, ".*") + ".crypt", bytes.pack("C*"))
  end
end

class Decoder
  def self.decode(file, table)
    decoded_array = []
    stream = IO.binread(File.basename(file, ".*") + ".crypt").unpack("B*")[0]
    index = 0
    bit_index = 0
    table = table.invert
    smallest_chunk = self.get_smallest_chunk(table)

    while index + smallest_chunk + bit_index < stream.length
      byte = stream[index...(index + smallest_chunk + bit_index)]
      if table[byte]
        decoded_array << table[byte].to_i(2)
        index += smallest_chunk + bit_index
        bit_index = 0
      else
        bit_index += 1
      end
    end

    File.binwrite("enc/" + File.basename(file, ".*"), decoded_array.pack("C*"))
  end

  def self.get_smallest_chunk(table)
    smallest_chunk = table.keys[0].length
    table.keys.each do |chunk|
      smallest_chunk = chunk.length if chunk.length < smallest_chunk
    endgit 
    smallest_chunk
  end
end

table = {}
chunk_size = 8

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

    [(ct + en + de), ]
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
  pp table
  Encoder.encode(ARGV[0], table, chunk_size)
  Decoder.decode(ARGV[0], table)
end

