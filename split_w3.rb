#!/usr/bin/ruby

src = File.binread('build/w3.raw').unpack('v*')
dst = []

blocks = [
  [010,    010],
  [  7,  04000],
  [  7,   -010],
  [  6, -04000],
  [  6,    010],
  [  5,  04000],
  [  5,   -010],
  [  4, -04000],
  [  4,    010],
  [  3,  04000],
  [  3,   -010],
  [  2, -04000],
  [  2,    010],
  [  1,  04000],
  [  1,   -010],
]

current_block_offset = -8 / 2

blocks.each do |blocks_count, offset_increment|
  blocks_count.times do |block_num|
    current_block_offset += offset_increment / 2

    32.times do |line|
      offset = current_block_offset + line * 32

      dst += src[offset, 4]
    end
  end
end

File.binwrite('build/w3_split.raw', dst.pack('v*'))
