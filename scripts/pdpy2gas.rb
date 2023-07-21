#!/usr/bin/ruby

require 'pathname'

BRANCH_INSTRUCTIONS = %w[
  bcc bcs beq bge bgt bhi bhis ble blo blos blt bmi bne bnz bpl br bvc bvs bze
].join('|')
SHIFTS = {
  '2' => 1,
  '4' => 2,
  '8' => 3,
  '16' => 4,
}

src_pathname = Pathname.new(ARGV[0])
dst_filename = src_pathname.basename.sub(/\..+$/, '.s').to_s.downcase

dst = File.open(dst_filename, 'w')
dst << "# vim: set tabstop=4 :\n\n"

src_pathname.read.each_line do |line|
  next if line.start_with?('; vim:')

  line.gsub!('#', '$')
  line.gsub!(';', '#')
  line.gsub!("\r", '')
  line.gsub!(/^(\s*\d+):/, '\1$:')
  line.gsub!(/(\$:) +(\t)/, '\1\2')
  line.gsub!(/[\s:]+ret$/i, 'RETURN')
  line.gsub!(/(#{BRANCH_INSTRUCTIONS})\s+\d+/i, '\0$')
  line.gsub!(/sob\s+r\d\s*,\s*\d+/i, '\0$')
  line.gsub!(/(?<![[:alnum:]_.])\d+\.?(?![[:alnum:]$_])/) do |number|
    next number[0..-2] if number.end_with?('.')
    next number if number.to_i(8) < 8

    "0#{number}"
  end
  line.gsub!(/0B([01]+)/, '0b\1')
  line.gsub!(/0X(\h+)/, '0x\1')
  line.gsub!(/\.(EVEN|BYTE|WORD)/) { |dir| dir.downcase }
  line.gsub!(/\.extern/i, '.global')
  line.gsub!(/\.LINK/i, '.org')
  line.gsub!(/(\.asci[iz]\s+)'(.+)'/i, '\1"\2"')
  line.gsub!(/\.asci[iz]'/i, 'huy')
  line.gsub!(/\.include\s+'(.+)'/i, '.include "\1"')
  line.gsub!(/insert_file\s+'(.+)'/i, '.incbin "\1"')
  line.gsub!(%r{RAW/.+}) { |str| str.sub('RAW', 'build').downcase }
  line.gsub!(/^ +\t/, "\t")
  line.gsub!(/\t +\t/, "\t\t")
  line.gsub!(/(.+[\s,]+)(\p{alpha}[\p{Alnum}_]+ \+ \p{Alpha}[\p{Alnum}_]+)(\(R[012345]\))/,
             "\t\t\t.set offset, \\2\n\\1offset\\3")
  line.gsub!(/\d+\s*\/\s*\d+/) do |str|
    dividend = str[/^\d+/]
    divisor = str[/\d+$/]
    next str if divisor.start_with?('0')
    next str unless %w[2 4 8 16].include?(divisor)

    "#{dividend} >> #{SHIFTS[divisor]}"
  end
  line.gsub!(/(?<=\s)(0\d*)(?=\$)/, '1\1')
  line.gsub!(/(?<=TRAP 0)(\s+\.)/i, ';\1')
  dst << line
end

if dst_filename == 'pt3play2.s'
  dst.puts
  dst.puts 'PARAM_DEVICES_AY1: .space 6'
  dst.puts 'PARAMETERS_AY1: .space PARAM_SIZE'
  dst.puts 'PARAM_DEVICES_AY2: .space 6'
  dst.puts 'PARAMETERS_AY2: .space PARAM_SIZE'
end

dst.close
