class Encoder
  def self.encode(file, table, chunk_size)
    data = File.binread(file).unpack("B*")[0]

    chunks = []; index = 0
    while index < data.length
      chunks << table[data[index...index + chunk_size]]
      index += chunk_size
    end

    bytes = []; index = 0
    unwritten_bytes = chunks.join("")
    unwritten_bytes += "0"*(8 - (unwritten_bytes.length % 8)) if unwritten_bytes.length % 8 != 0

    while index < unwritten_bytes.length
      bytes << unwritten_bytes[index...index + 8].to_i(2)
      index += 8
    end

    File.binwrite(File.basename(file, ".*") + ".crypt", bytes.pack("C*"))
  end
end