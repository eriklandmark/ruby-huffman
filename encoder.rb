class Encoder
  def self.encode(file, table, chunk_size)
    data = File.binread(file).unpack("B*")[0]

    chunks = []; index = 0
    while index < data.length
      chunks << table[data[index...index + chunk_size]]
      index += chunk_size
    end

    unwritten_bytes = chunks.join("")
    compressed_length = unwritten_bytes.length
    unwritten_bytes += "0"*(8 - (compressed_length % 8)) if compressed_length % 8 != 0
    bytes = "#{{file_name: File.basename(file), compressed_length: compressed_length, table: table}.to_json}\r".bytes
    index = 0

    while index < unwritten_bytes.length
      bytes << unwritten_bytes[index...index + 8].to_i(2)
      index += 8
    end

    File.binwrite(File.basename(file, ".*") + ".crypt", bytes.pack("C*"))
  end
end