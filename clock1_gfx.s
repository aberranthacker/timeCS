.global CLOCK1
.global digits1
.global digits2
.global numbers
.global circle_left_off_0
.global circle_left_off_1
.global circle_left_off_2
.global circle_left_off_3
.global circle_left_off_4
.global circle_left_off_5
.global circle_left_off_6
.global circle_left_off_7
.global circle_left_on_0
.global circle_left_on_1
.global circle_left_on_2
.global circle_left_on_3
.global circle_left_on_4
.global circle_left_on_5
.global circle_left_on_6
.global circle_left_on_7
.global circle_right_off_0
.global circle_right_off_1
.global circle_right_off_2
.global circle_right_off_3
.global circle_right_off_4
.global circle_right_off_5
.global circle_right_off_6
.global circle_right_off_7
.global circle_right_on_0
.global circle_right_on_1
.global circle_right_on_2
.global circle_right_on_3
.global circle_right_on_4
.global circle_right_on_5
.global circle_right_on_6
.global circle_right_on_7

CATALOGUE:
            .word CLOCK1 - CATALOGUE             #  +00
            .word digits1 - CATALOGUE            #  +02
            .word digits2 - CATALOGUE            #  +04
            .word numbers - CATALOGUE            #  +06

            .word circle_left_off_0 - CATALOGUE  # +010
            .word circle_left_off_1 - CATALOGUE  # +012
            .word circle_left_off_2 - CATALOGUE  # +014
            .word circle_left_off_3 - CATALOGUE  # +016
            .word circle_left_off_4 - CATALOGUE  # +020
            .word circle_left_off_5 - CATALOGUE  # +022
            .word circle_left_off_6 - CATALOGUE  # +024
            .word circle_left_off_7 - CATALOGUE  # +026

            .word circle_left_on_0 - CATALOGUE   # +030
            .word circle_left_on_1 - CATALOGUE   # +032
            .word circle_left_on_2 - CATALOGUE   # +034
            .word circle_left_on_3 - CATALOGUE   # +036
            .word circle_left_on_4 - CATALOGUE   # +040
            .word circle_left_on_5 - CATALOGUE   # +042
            .word circle_left_on_6 - CATALOGUE   # +044
            .word circle_left_on_7 - CATALOGUE   # +046

            .word circle_right_off_0 - CATALOGUE # +050
            .word circle_right_off_1 - CATALOGUE # +052
            .word circle_right_off_2 - CATALOGUE # +054
            .word circle_right_off_3 - CATALOGUE # +056
            .word circle_right_off_4 - CATALOGUE # +060
            .word circle_right_off_5 - CATALOGUE # +062
            .word circle_right_off_6 - CATALOGUE # +064
            .word circle_right_off_7 - CATALOGUE # +066

            .word circle_right_on_0 - CATALOGUE  # +070
            .word circle_right_on_1 - CATALOGUE  # +072
            .word circle_right_on_2 - CATALOGUE  # +074
            .word circle_right_on_3 - CATALOGUE  # +076
            .word circle_right_on_4 - CATALOGUE  #+0100
            .word circle_right_on_5 - CATALOGUE  #+0102
            .word circle_right_on_6 - CATALOGUE  #+0104
            .word circle_right_on_7 - CATALOGUE  #+0106

CLOCK1:
            .incbin "build/clock1/clock1.raw"

digits1:
            .incbin "build/clock1/digits1.raw"

digits2:
            .incbin "build/clock1/digits1_2.raw"

numbers:
            .incbin "build/clock1/numbers1.raw"

circle_left_off_0:
            .incbin "build/clock1/circle1_left_off_0.raw"
circle_left_off_1:
            .incbin "build/clock1/circle1_left_off_1.raw"
circle_left_off_2:
            .incbin "build/clock1/circle1_left_off_2.raw"
circle_left_off_3:
            .incbin "build/clock1/circle1_left_off_3.raw"
circle_left_off_4:
            .incbin "build/clock1/circle1_left_off_4.raw"
circle_left_off_5:
            .incbin "build/clock1/circle1_left_off_5.raw"
circle_left_off_6:
            .incbin "build/clock1/circle1_left_off_6.raw"
circle_left_off_7:
            .incbin "build/clock1/circle1_left_off_7.raw"

circle_left_on_0:
            .incbin "build/clock1/circle1_left_on_0.raw"
circle_left_on_1:
            .incbin "build/clock1/circle1_left_on_1.raw"
circle_left_on_2:
            .incbin "build/clock1/circle1_left_on_2.raw"
circle_left_on_3:
            .incbin "build/clock1/circle1_left_on_3.raw"
circle_left_on_4:
            .incbin "build/clock1/circle1_left_on_4.raw"
circle_left_on_5:
            .incbin "build/clock1/circle1_left_on_5.raw"
circle_left_on_6:
            .incbin "build/clock1/circle1_left_on_6.raw"
circle_left_on_7:
            .incbin "build/clock1/circle1_left_on_7.raw"

circle_right_off_0:
            .incbin "build/clock1/circle1_right_off_0.raw"
circle_right_off_1:
            .incbin "build/clock1/circle1_right_off_1.raw"
circle_right_off_2:
            .incbin "build/clock1/circle1_right_off_2.raw"
circle_right_off_3:
            .incbin "build/clock1/circle1_right_off_3.raw"
circle_right_off_4:
            .incbin "build/clock1/circle1_right_off_4.raw"
circle_right_off_5:
            .incbin "build/clock1/circle1_right_off_5.raw"
circle_right_off_6:
            .incbin "build/clock1/circle1_right_off_6.raw"
circle_right_off_7:
            .incbin "build/clock1/circle1_right_off_7.raw"

circle_right_on_0:
            .incbin "build/clock1/circle1_right_on_0.raw"
circle_right_on_1:
            .incbin "build/clock1/circle1_right_on_1.raw"
circle_right_on_2:
            .incbin "build/clock1/circle1_right_on_2.raw"
circle_right_on_3:
            .incbin "build/clock1/circle1_right_on_3.raw"
circle_right_on_4:
            .incbin "build/clock1/circle1_right_on_4.raw"
circle_right_on_5:
            .incbin "build/clock1/circle1_right_on_5.raw"
circle_right_on_6:
            .incbin "build/clock1/circle1_right_on_6.raw"
circle_right_on_7:
            .incbin "build/clock1/circle1_right_on_7.raw"
