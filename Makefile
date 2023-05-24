AS=~/opt/binutils-pdp11/pdp11-dec-aout/bin/as
LD=~/opt/binutils-pdp11/pdp11-dec-aout/bin/ld

AKG_PLAYER_PATH = ../akg_player
BUILD_TOOLS_PATH= ../aku/uknc/build_tools

AOUT2SAV = $(BUILD_TOOLS_PATH)/aout2sav.rb
BMP_TO_RAW = $(BUILD_TOOLS_PATH)/bmp_to_raw.rb
BUILD_DSK = $(BUILD_TOOLS_PATH)/build_dsk.rb
FORMAT_LIST = $(BUILD_TOOLS_PATH)/format_list.rb
UPDATE_DISKMAP = $(BUILD_TOOLS_PATH)/update_disk_map.rb
# 2.38
MAKEFLAGS += --silent --jobs
LDFLAGS += --strip-all
INCS = -I../aku/uknc -I$(AKG_PLAYER_PATH)

.SUFFIXES:
.SUFFIXES: .s .o
.PHONY: clean

# --just-symbols= -R include only symbols from the file
# --print-map -M
# --strip-all -s

COMMON = core_defs.s ../aku/uknc/hwdefs.s ../aku/uknc/macros.s

all : pre-build build/demo.dsk

pre-build :
	mkdir -p build

clean :
	rm -rf build/*

# demo.dsk ------------------------------------------------------------------{{{
build/demo.dsk : $(BUILD_DSK) \
		 $(BUILD_TOOLS_PATH)/dsk_image_constants.rb \
		 $(UPDATE_DISKMAP) \
		 dsk_flist \
		 build/bootsector.bin \
		 build/ppu_module.bin \
		 build/main.bin
	$(UPDATE_DISKMAP) dsk_flist build/bootsector.map.txt build/bootsector.bin
	$(BUILD_DSK) dsk_flist build/demo.dsk
# demo.dsk ------------------------------------------------------------------}}}

# bootsector.bin ------------------------------------------------------------{{{
build/bootsector.bin : build/bootsector.o \
                       build/main.o \
                       build/ppu.o
	$(LD) $(LDFLAGS) -M \
		-T linker_scripts/bootsector.cmd \
		-R build/main.o \
		-R build/ppu.o > build/bootsector.map.txt
	chmod -x build/bootsector.bin

build/bootsector.o : $(COMMON) \
                     bootsector.s
	$(AS) -al bootsector.s -o build/bootsector.o | $(FORMAT_LIST)
# bootsector.bin ------------------------------------------------------------}}}

# ppu_module.bin ------------------------------------------------------------{{{
build/ppu_module.bin : build/ppu.o \
                       build/main.o
	$(LD) $(LDFLAGS) -T linker_scripts/ppu.cmd -R build/main.o
	ruby $(AOUT2SAV) build/ppu.out -b -s -o build/ppu_module.bin
build/ppu.o : $(COMMON) \
              ppu.s \
              ppu/interrupts_handlers.s \
              $(AKG_PLAYER_PATH)/akg_player.s \
              $(AKG_PLAYER_PATH)/akg_sound_effects.s
	$(AS) ppu.s $(INCS) -o build/ppu.o | $(FORMAT_LIST)
# ppu_module.bin ------------------------------------------------------------}}}

# main.bin ------------------------------------------------------------------{{{
build/main.bin : build/main.o
	$(LD) $(LDFLAGS) build/main.o -o build/main.out
	ruby $(AOUT2SAV) build/main.out -b -s -o build/main.bin
build/main.o : $(COMMON) \
               main.s \
               build/c2ay_toyhifi.raw
	$(AS) main.s $(INCS) -al -o build/main.o | $(FORMAT_LIST)
# main.bin ------------------------------------------------------------------}}}

build/c2ay_toyhifi.raw : $(BMP_TO_RAW) gfx/c2ay_toyhifi.bmp
	$(BMP_TO_RAW) gfx/c2ay_toyhifi.bmp build/c2ay_toyhifi.raw
