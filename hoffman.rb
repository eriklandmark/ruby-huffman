require 'pp'

time = Time.now

text = File.read("long_text.txt")
#text = "\"this is an example of a huffman tree\""

class Node
  attr_accessor :left, :right, :symbol, :freq
  @left = nil
  @right = nil
  @symbol = ""
  @frequency = 0

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
  @nodes = chars_map.sort_by{|_,v|v}
  @tree = Node.new(nil, nil, "", text.length)
  create_tree(@tree, 1, Math.log2(@nodes.length).ceil)
  chars_map.keys.reduce({}){|acc, sym| get_path("0", @tree.left, sym); get_path("1", @tree.right, sym); acc[sym] = @path; @path = ""; acc}
end

def create_tree(node, layer, max_layer)
  if layer >= max_layer
    n = @nodes.delete_at(0)
    unless n.nil?
      node.left = Node.new(nil, nil , n[0], n[1])
    end
    n = @nodes.delete_at(0)
    unless n.nil?
      node.right = Node.new(nil, nil , n[0], n[1])
    end
  else
    if @nodes.length >= 2
      node.left = Node.new(nil, nil, "", 0)
      create_tree(node.left, layer + 1, max_layer)
    end
    if @nodes.length >= 1
      node.right = Node.new(nil, nil, "", 0)
      create_tree(node.right, layer + 1, max_layer)
    end
  end
end

def encode(path, text)
  text.chars.reduce([]){|acc, char| acc << path[char]}.join("")
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

def decode(path, stream)
  decoded_array = []
  path = path.invert
  stream.chars.reduce(""){|acc, char| acc += char; unless path[acc].nil?; decoded_array << path[acc]; acc = "" end; acc}
  decoded_array.join("")
end

def write_to_file(stream)
  file_buff = []
  (stream.length / 8.0).ceil.times do |i|
    byte = (stream[i...i + (8 * i > stream.length ? 8 * i - stream.length : 8)].to_i(2))
    file_buff << byte
  end

  File.binwrite("encoded", file_buff.pack("C*"))
end

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
encoded_length = (encoded.length / 8.0).ceil
puts encoded_length

write_to_file(encoded)

print "Starting decoding... "
decoded = decode(path, encoded)
puts "Done!"
print "Decoded length (bytes): "
puts decoded.length

IO.write("decoded", decoded)

puts "============"
puts "Total time: " + time_diff_milli(time, Time.now).to_s + " seconds"
puts "Compression ratio: " + ((1 -(encoded_length.to_f / original_length)) * 100).round(2).to_s + "%"



