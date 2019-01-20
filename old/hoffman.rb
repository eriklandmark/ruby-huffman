#require pp'
require "benchmark"
require 'ruby-prof'
require "byebug"

#time = Time.now

#text = File.read("long_text.txt")
text = "The path of the righteous man is beset on all sides by the iniquities of the selfish and the tyranny of evil men. Blessed is he who, in the name of charity and good will, shepherds the weak through the valley of darkness, for he is truly his brother's keeper and the finder of lost children."
#text = "this is an example of a huffman tree"

class Node
  attr_accessor :left, :right, :symbol, :frequency

  def initialize(left, right, symbol, freq)
    @left = left
    @right = right
    @symbol = symbol
    @frequency = freq
  end
end

@tree = nil
@nodes = []
@path = ""

def time_diff_milli(start, finish)
  (finish - start).round(2)
end

def get_table(text)
  chars_map = text.chars.reduce({}) {|acc, char| acc[char] = acc[char].nil? ? 1 : acc[char] + 1; acc}
  @nodes = chars_map.sort_by {|_, v| v}
  @tree = Node.new(nil, nil, "", text.length)
  create_tree(@tree, 1, Math.log2(@nodes.length).ceil)
  chars_map.keys.reduce({}) do |acc, sym|
    get_path("0", @tree.left, sym)
    get_path("1", @tree.right, sym)
    acc[sym] = @path.chars.map {|v| v.to_i}
    @path = ""
    acc
  end
end

def create_tree(node, layer, max_layer)
  if layer >= max_layer
    n = @nodes.delete_at(0)
    unless n.nil?
      node.left = Node.new(nil, nil, n[0], n[1])
    end
    n = @nodes.delete_at(0)
    unless n.nil?
      node.right = Node.new(nil, nil, n[0], n[1])
    end
  else
    if @nodes.length == 1
      n = @nodes.delete_at(0)
      node.symbol = n[0]
      node.frequency = n[1]
    elsif @nodes.length >= 2
      node.left = Node.new(nil, nil, "", 0)
      create_tree(node.left, layer + 1, max_layer)
      node.right = Node.new(nil, nil, "", 0)
      create_tree(node.right, layer + 1, max_layer)
    end
  end
end

def encode(table, text)
  chunks = text.chars.reduce([]) do |acc, char|
    acc << table[char]
  end

  bytes = chunks.flatten.each_slice(8).reduce([]) do |acc, byte|
    acc << byte.join("").to_i(2)
    acc
  end

  File.binwrite("encode", bytes.pack("C*"))
end

def get_path(path, node, target)
  if node.symbol == target
    @path = path
  else
    unless node.left.nil?
      get_path(path + "0", node.left, target)
    end
    unless node.right.nil?
      get_path(path + "1", node.right, target)
    end
  end
end

def decode(path)
  decoded_array = []
  path = path.invert

  #result = RubyProf.profile do
  mes = Benchmark.measure do
    str = IO.binread("encode").unpack("B*").join("").chars
    puts "Den"
    str.reduce([]) do |acc, char|
      acc << char.to_i
      unless path[acc] == nil
        decoded_array << path[acc]
        acc = []
      end
      acc
    end
  end

  #RubyProf::GraphPrinter.new(result).print(STDOUT, {})
  puts mes

  decoded_array.join("")
end

encoded = ""

measure = Benchmark.measure {
  print "Original length (bytes): "
  original_length = text.length
  puts original_length

  print "Creating node tree... "
  path = get_table(text)
  pp path
  puts "Done!"
  print "Starting encoding... "
  encoded = encode(path, text)
  puts "Done!"
  print "Encoded length (bytes): "
  puts encoded

  print "Starting decoding... "
  decoded = decode(path)
  puts "Done!"
  print "Decoded length (bytes): "
  puts decoded.length
  IO.write("decoded", decoded)
}

puts "============"
#puts "Total time: " + time_diff_milli(time, Time.now).to_s + " seconds"
puts "Compression ratio: " + ((1 - (encoded.to_f / text.length.to_f)) * 100).round(2).to_s + "%"
puts measure