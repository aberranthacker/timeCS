AS=~/opt/binutils-pdp11/pdp11-dec-aout/bin/as
LD=~/opt/binutils-pdp11/pdp11-dec-aout/bin/ld
# 2.38
MAKEFLAGS += --silent --jobs
LDFLAGS += --strip-all
INCS = -I../aku/uknc -I../akg_player 

.SUFFIXES:
.SUFFIXES: .s .o
.PHONY: clean

# --just-symbols= -R include only symbols from the file
# --print-map -M
# --strip-all -s

AOUT2SAV = ../aku/uknc/build_tools/aout2sav.rb
FORMAT_LIST_TOOL = ../aku/uknc/build_tools/format_list.rb
UPDATE_DISKMAP = ../aku/uknc/build_tools/update_bootsector_disk_map.rb 
BUILD_DSK = ../aku/uknc/build_tools/build_dsk.rb 

COMMON = core_defs.s ../aku/uknc/hwdefs.s ../aku/uknc/macros.s

all : pre-build build/demo.dsk

pre-build :
	mkdir -p build

clean :
	rm -rf build/*

# demo.dsk ------------------------------------------------------------------{{{
build/demo.dsk : ../aku/uknc/build_tools/build_dsk.rb \
			     ../aku/uknc/build_tools/dsk_image_constants.rb \
			     ../aku/uknc/build_tools/update_bootsector_disk_map.rb \
			     build/bootsector.bin \
			     build/ppu_module.bin \
			     build/core.bin
	$(UPDATE_DISKMAP) dsk_files_list build/bootsector.map.txt build/bootsector.bin
	$(BUILD_DSK) dsk_files_list build/demo.dsk
# demo.dsk ------------------------------------------------------------------}}}

# bootsector.bin ------------------------------------------------------------{{{
build/bootsector.bin : build/bootsector.o \
                       build/core.o \
                       build/ppu.o
	$(LD) $(LDFLAGS) -M \
		-T linker_scripts/bootsector.cmd \
		-R build/core.o \
		-R build/ppu.o > build/bootsector.map.txt
	chmod -x build/bootsector.bin

build/bootsector.o : $(COMMON) \
                     bootsector.s
	$(AS) -al bootsector.s -o build/bootsector.o | $(FORMAT_LIST_TOOL)
# bootsector.bin ------------------------------------------------------------}}}

# ppu_module.bin ------------------------------------------------------------{{{
build/ppu_module.bin : build/ppu.o \
                       build/core.o
	$(LD) $(LDFLAGS) -T linker_scripts/ppu.cmd -R build/core.o
	ruby $(AOUT2SAV) build/ppu.out -b -s -o build/ppu_module.bin
build/ppu.o : $(COMMON) \
              ppu.s \
              ppu/interrupts_handlers.s \
              ../akg_player/akg_player.s \
              ../akg_player/akg_sound_effects.s
	$(AS) ppu.s $(INCS) -o build/ppu.o | $(FORMAT_LIST_TOOL)
# ppu_module.bin ------------------------------------------------------------}}}

# core.bin ------------------------------------------------------------------{{{
build/core.bin : build/core.o
	$(LD) $(LDFLAGS) build/core.o -o build/core.out
	ruby $(AOUT2SAV) build/core.out -b -s -o build/core.bin
build/core.o : $(COMMON) \
               core.s \
               stars.s
	$(AS) core.s $(INCS) -al -o build/core.o | $(FORMAT_LIST_TOOL)
# core.bin ------------------------------------------------------------------}}}
