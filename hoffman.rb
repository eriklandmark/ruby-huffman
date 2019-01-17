#require pp'
require 'stackprof'
require "benchmark"

#time = Time.now

text = File.read("long_text.txt")
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
  chars_map.keys.reduce({}) {|acc, sym| get_path("0", @tree.left, sym); get_path("1", @tree.right, sym); acc[sym] = @path; @path = ""; acc}
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

def encode(path, text)
  File.open("encoded", "wb") do |file|
    file.write(text.chars.reduce([]) {|acc, char| acc << path[char]}.join("").scan(/.{8}/).reduce([]) { |acc, byte| acc << byte.to_i(2); acc}.pack("C*"))
  end
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
  byte = ""
  path = path.invert
  decoded_array = IO.binread("encoded").unpack("B*").join("").chars.reduce([]) do |acc, char|
    byte += char
    unless path[byte].nil?
      acc << path[byte]
      byte = ""
    end
    acc
  end

  decoded_array.join("")
end

encoded = ""

measure = Benchmark.measure {
  print "Original length (bytes): "
  original_length = text.length
  puts original_length

  print "Creating node tree... "
  path = get_table(text)
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