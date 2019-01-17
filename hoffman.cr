#require 'pp'

time = Time.now

#text = File.read("long_text.txt")
text = "\"this is an example of a huffman tree\""

class Node
  property :left, :right, :symbol, :frequency

  def initialize(left, right, symbol, freq)
    @left = left
    @right = right
    @symbol = symbol
    @frequency = freq
  end
end

class Encoder
    property :nodes, :path, :tree

    def intialize()
        @nodes = [] of Array(Node) | Nil
        @path = ""
        @tree = nil | Node
    end
end

def time_diff_milli(start, finish)
  (finish - start).round(2)
end



def get_table(text)
  encoder = Encoder.new
  chars_map = text.chars.reduce({} of Char => Int32) {|acc, char| acc[char] = acc[char].nil? ? 1 : acc[char] + 1; acc}
  encoder.nodes = chars_map.to_a.sort_by{|k,v|v}
  encoder.tree = Node.new(nil, nil, "", text.size)
  create_tree(encoder, encoder.tree, 1, Math.log2(encoder.nodes.size).ceil)
  chars_map.keys.reduce({} of String => String){|acc, sym| get_path("0", encoder.tree.left, sym); get_path("1", encoder.tree.right, sym); acc[sym] = encoder.path; encoder.path = ""; acc}
end

def create_tree(encoder, node, layer, max_layer)
  if layer >= max_layer
    n = encoder.nodes.delete_at(0)
    unless n.nil?
      node.left = Node.new(nil, nil , n[0], n[1])
    end
    n = encoder.nodes.delete_at(0)
    unless n.nil?
      node.right = Node.new(nil, nil , n[0], n[1])
    end
  else
    if encoder.nodes.size >= 2
      node.left = Node.new(nil, nil, "", 0)
      create_tree(node.left, layer + 1, max_layer)
    end
    if encoder.nodes.size >= 1
      node.right = Node.new(nil, nil, "", 0)
      create_tree(node.right, layer + 1, max_layer)
    end
  end
end

def encode(path, text)
  text.chars.reduce([] of String){|acc, char| acc << path[char]}.join("")
end

def get_path(path, node, target)
  if node.symbol == target
    encoder.path = path
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
  decoded_array = [] of String
  path = path.invert
  stream.chars.reduce("") do |acc, char|
    acc += char
    unless path[acc].nil?
      decoded_array << path[acc]
      acc = ""
    end
  end
  decoded_array.join("")
end

def write_to_file(stream)
  file_buff = [] of Byte
  (stream.size / 8.0).ceil.times do |i|
    byte = (stream[i...i + (8 * i > stream.size ? 8 * i - stream.size : 8)].to_i(2))
    file_buff << byte
  end

  File.binwrite("encoded", file_buff.pack("C*"))
end

print "Original length (bytes): "
original_length = text.size
puts original_length


print "Creating node tree... "
path = get_table(text)
puts "Done!"

print "Starting encoding... "
encoded = encode(path, text)
puts "Done!"
print "Encoded length (bytes): "
encoded_length = (encoded.size / 8.0).ceil
puts encoded_length

write_to_file(encoded)

print "Starting decoding... "
decoded = decode(path, encoded)
puts "Done!"
print "Decoded length (bytes): "
puts decoded.size

IO.write("decoded", decoded)

puts "============"
puts "Total time: " + time_diff_milli(time, Time.now).to_s + " seconds"
puts "Compression ratio: " + ((1 -(encoded_length.to_f / original_length)) * 100).round(2).to_s + "%"



