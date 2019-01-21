class Decoder
  def self.decode(file)
    decoded_array = []
    file_stream = IO.binread(File.basename(file, ".*") + ".crypt").unpack("C*")
    file_table = JSON.parse(file_stream.shift(file_stream.find_index(13) + 1).map(&:chr).join(""))
    stream = file_stream.map {|b| "%08b" % b}.join("")
    #stream = file_stream.map {|b| bb = b.to_s(2); "0"*(8-bb.length) + bb}.join("")
    index = 0
    bit_index = 0
    table = file_table["table"].invert
    smallest_chunk = table.keys.reduce(table.keys[0].length) {|acc, chunk| acc = chunk.length if chunk.length < acc; acc }

    while index < file_table["compressed_length"]
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
    end

    File.binwrite("enc/" + file_table["file_name"], decoded_array.pack("C*"))
  end
end