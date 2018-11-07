module Zip
  # Stores the UTF-8 version of the file name field
  class ExtraField::UnicodePath < ExtraField::Generic
    HEADER_ID = [0x7075].pack('v')
    SUPPORTED_VERSIONS = [1]
    register_map

    def initialize(binstr = nil)
      @version = 1
      @entry_name_crc32 = 0
      @value = ""

      binstr && merge(binstr)
    end

    attr_accessor :version, :entry_name_crc32, :value

    # Return @value if CRC32 checksum of entry_name matches with @entry_name_crc32.
    def unicode_name_for(entry_name)
      if Zlib.crc32(entry_name) == @entry_name_crc32
        @value
      else
        # if not, just return the entry_name.
        entry_name
      end
    end

    def entry_name=(entry_name)
      @entry_name_crc32 = Zlib.crc32(entry_name)
      @value = entry_name.encode("UTF-8")
    end

    def merge(binstr)
      return if binstr.empty?

      size, content = initial_parse(binstr)
      (size && content) || return
      return if size < 5

      version = content[0].unpack("C")[0]
      return unless SUPPORTED_VERSIONS.include? version

      name = content[5..-1].force_encoding("UTF-8")
      return unless name.valid_encoding?

      @version = version
      @entry_name_crc32 = content[1, 4].unpack("V")[0]
      @value = name
    end

    def ==(other)
      @version == other.version &&
        @entry_name_crc32 == other.entry_name_crc32 &&
        @value == other.value
    end

    # it is stored at both local and central directory header
    def pack_for_local
      pack_for_c_dir
    end

    def pack_for_c_dir
      s = ''.force_encoding(Encoding::BINARY)

      s << [@version].pack("C")
      s << [@entry_name_crc32].pack("V")
      s << @value.force_encoding(Encoding::BINARY)

      s
    end
  end
end
