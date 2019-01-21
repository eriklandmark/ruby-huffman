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

    {chunks: chunk_map.keys, tree: tree(chunk_map.sort_by { |_,v | v[:count]})}
  end

  def self.create_table(file, chunk_size)
    data = File.binread(file).unpack("B*")[0]
    tree = self.build(data, chunk_size)
    paths = {}
    tree[:chunks].each do |chunk|
      r_get_paths(tree[:tree][:left], chunk, paths)
      r_get_paths(tree[:tree][:right], chunk, paths)
    end

    paths
  end

  private

  def self.tree(chunks)
    tree = {}
    r_tree(chunks, tree, 1, Math.log2(chunks.length).ceil)
    tree
  end

  def self.r_tree(sorted_chunks, node, layer, max_layer)
    if layer <= max_layer
      nodes_left = sorted_chunks.count {|x| !x[1][:taken]}
      if nodes_left >= 2
        r_tree(sorted_chunks, node[:left] = {}, layer + 1, max_layer)
        r_tree(sorted_chunks, node[:right] = {}, layer + 1, max_layer)
      elsif nodes_left == 1
        new_node = sorted_chunks.find {|chunk| !chunk[1][:taken]}
        new_node[1][:taken] = true
        node[:byte] = new_node[0]
        #node[:frequency] = new_node[1][:count]
      end
    else
      new_node = sorted_chunks.find {|chunk| !chunk[1][:taken]}
      if new_node
        new_node[1][:taken] = true
        node[:left] = {byte: new_node[0]} #, frequency: new_node[1][:count]}
      end
      new_node = sorted_chunks.find {|chunk| !chunk[1][:taken]}
      if new_node
        new_node[1][:taken] = true
        node[:right] = {byte: new_node[0]} #, frequency: new_node[1][:count]}
      end
    end
  end

  def self.r_get_paths(node, target, paths, path = nil)
    if node[:byte] == target
      paths[target] = path
    else
      r_get_paths(node[:left], target, paths, path ? path + "0": "0") if node[:left]
      r_get_paths(node[:right], target, paths, path ? path + "1": "1") if node[:right]
    end
  end
end