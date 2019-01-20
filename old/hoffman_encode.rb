require 'pp'
text = "The path of the righteous man is beset on all sides by the iniquities of the selfish and the tyranny of evil men. Blessed is he who, in the name of charity and good will, shepherds the weak through the valley of darkness, for he is truly his brother's keeper and the finder of lost children."

class Node
  attr_accessor :left, :right, :symbol, :freq
  @left = nil
  @right = nil
  @symbol = ""
  @freq = 0
end

@tree = nil
@nodes = []

def get_table(text)
  chars_map = {}

  text.chars.each do |char|
    chars_map[char] = chars_map[char].nil? ? 1 : chars_map[char] + 1
  end

  size = 2
  chars_array = chars_map.sort_by { |_,v | v}.reverse
  last_nodes = []
  pp chars_array

  while size <= chars_array.length
    current_nodes = []
    chars_array[0...size].each_with_index do |char, i|
      print char
      chars_array.delete_at(0)
      bit = last_nodes[(i / 2).floor].nil? ? (i % 2).to_s: last_nodes[(i / 2).floor] + (i % 2).to_s
      chars_map[char[0]] = bit
      current_nodes << bit
    end
    puts ""
    last_nodes = current_nodes
    size *= 2
    if chars_array.length == 0
      break
    elsif size > chars_array.length
      size = chars_array.length
    end
  end

  {node: chars_map, symbols: chars_map.keys}
end

def create_tree(node)
  unless node.nil?
    node.left = @nodes.pop
    node.right = @nodes.pop
    create_tree(node.left)
    create_tree(node.right)
  end
end

@en_path = ""

def encode(table, text)
  encoded_text = ""
  paths = {}
  table[:symbols].each do |sym|
    get_path("0", table[:node].left, sym)
    get_path("1", table[:node].right, sym)
    paths[sym] = @en_path
    @en_path = ""
  end

  pp paths

  text.chars.each do |char|
    encoded_text += paths[char]
  end
  encoded_text
end

def get_path(path, node, target)
  if node.symbol == target
    @en_path = path
  else
    unless node.left.nil?
      get_path(path + "0", node.left, target)
    end
    unless node.right.nil?
      get_path(path + "1", node.right, target)
    end
  end
end

def decode(table, text)
  start_index = 0
  end_index = 0
  decoded_text = ""

end

p text
table = get_table(text)
pp table
#encoded = encode(table, text)
#p encoded
#p decode(table, encoded)


=begin

file_buff = []
(encoded.length / 8.0).ceil.times do |i|
  byte = (encoded[i...i + (8 * i > encoded.length ? 8 * i - encoded.length : 8)].to_i(2))
  #p encoded[i...i + (8 * i > encoded.length ? 8 * i - encoded.length : 8)]
  #p byte
  file_buff << byte
end

File.binwrite("encode", file_buff.pack("C*"))

=end


