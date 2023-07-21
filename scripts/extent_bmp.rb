#!/usr/bin/ruby

files = [
 #{ fn: 'for_conversion/circle1_left_state_0.bmp', gravity: :Center}, # 0   8  28
  { fn: 'for_conversion/circle1_left_state_1.bmp', gravity: :East},   # 1  12  32
  { fn: 'for_conversion/circle1_left_state_2.bmp', gravity: :East},   # 2  12  32
  { fn: 'for_conversion/circle1_left_state_3.bmp', gravity: :West},   # 3  12  28
  { fn: 'for_conversion/circle1_left_state_4.bmp', gravity: :West},   # 4  12  20
 #{ fn: 'for_conversion/circle1_left_state_5.bmp', gravity: :Center}, # 5   8  12
 #{ fn: 'for_conversion/circle1_left_state_6.bmp', gravity: :Center}, # 6   8   4
  { fn: 'for_conversion/circle1_left_state_7.bmp', gravity: :West},   # 7   4   0

 #{ fn: 'for_conversion/circle1_right_state_0.bmp', gravity: :Center}, # 0   8  16
  { fn: 'for_conversion/circle1_right_state_1.bmp', gravity: :East},   # 1  12   4
  { fn: 'for_conversion/circle1_right_state_2.bmp', gravity: :West},   # 2  12   0
  { fn: 'for_conversion/circle1_right_state_3.bmp', gravity: :West},   # 3  12   0
  { fn: 'for_conversion/circle1_right_state_4.bmp', gravity: :East},   # 4  12   4
 #{ fn: 'for_conversion/circle1_right_state_5.bmp', gravity: :Center}, # 5   8  16
 #{ fn: 'for_conversion/circle1_right_state_6.bmp', gravity: :Center}, # 6   8  24
 #{ fn: 'for_conversion/circle1_right_state_7.bmp', gravity: :West},   # 7   8  32
]

%w[on off].each do |state|
  files.each do |options|
    fn = options[:fn].gsub('state', state)
    bmp = File.binread(fn)

    signature          = bmp[0,2]
    image_width        = bmp[0x12,4].unpack1('V') # 32-bit unsigned, VAX (little-endian) byte order
    image_height       = bmp[0x16,4].unpack1('V') # 32-bit unsigned, VAX (little-endian) byte order
    raise "#{options.src_filename} : Unknown file type." unless signature == 'BM'

    dst_width = if options[:gravity] == :Center
                  image_width + 8
                else
                  (image_width + 7) & 0xFFF8
                end

    dst_size = "#{dst_width}x#{image_height}"
    dst_fn = "gfx/clock1/#{fn[/[^\/]+$/]}"

    puts "#{dst_fn} #{image_width}x#{image_height} -> #{dst_size}"

    `convert #{fn} -resize #{dst_size} -gravity #{options[:gravity]} -background Black -extent #{dst_size} -colors 16 #{dst_fn}`
  end
end
