class Decoder
  def self.decode(file, table)
    decoded_array = []
    stream = IO.binread(File.basename(file, ".*") + ".crypt").unpack("B*")[0]
    index = 0
    bit_index = 0
    table = table.invert
    smallest_chunk = self.get_smallest_chunk(table)

    while index < stream.length
      byte = stream[index...(index + smallest_chunk + bit_index)]
      if table[byte]
        byte_parts = (table[byte].length / 8).ceil
        if byte_parts >= 1
          byte_part = 0
          while byte_part < byte_parts * 8
            decoded_array << table[byte][byte_part...byte_part + 8].to_i(2)
            byte_part += 8
          end
        else
          decoded_array << table[byte].to_i(2)
        end
        index += smallest_chunk + bit_index
        bit_index = 0
      else
        bit_index += 1
      end
      # p "#{index} / #{stream.length - 1}"
    end

    File.binwrite("enc/" + File.basename(file, ".*"), decoded_array.pack("C*"))
  end

  def self.get_smallest_chunk(table)
    smallest_chunk = table.keys[0].length
    table.keys.each do |chunk|
      smallest_chunk = chunk.length if chunk.length < smallest_chunk
    end
    smallest_chunk
  end
end