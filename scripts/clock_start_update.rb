#!/usr/bin/ruby

NM = '~/opt/binutils-pdp11/pdp11-dec-aout/bin/nm'

dot_o_file = 'build/player.o'
defs_file = 'clock_defs.s'
label = 'ClockScreenStart'

nm_output = `#{NM} #{dot_o_file} -g`
lines = File.read(defs_file).lines.to_a

addr = nm_output[/[0-9a-f]{4}(?=\sT\s#{label})/m].to_i(16)
idx = lines.find_index { |line| /\.equiv #{label}/.match?(line) }
defs_addr = lines[idx][/(?<=\.equiv #{label}, 0x)[0-9a-f]{4}/i].to_i(16)
puts "#{label}: #{addr}"

return if addr == defs_addr

hex = "0x#{addr.to_s(16).upcase.rjust(4, '0')}"
oct = "0#{addr.to_s(8)}"
dec = addr
lines[idx] = ".equiv #{label}, #{hex} # #{dec} #{oct} # auto-generated during a build\n"

File.write(defs_file, lines.join)
