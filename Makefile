BIN_UTILS_PATH   = ~/opt/binutils-pdp11/pdp11-dec-aout/bin
BUILD_TOOLS_PATH = ../aku/uknc/build_tools

AS = $(BIN_UTILS_PATH)/as
LD = $(BIN_UTILS_PATH)/ld

AOUT2SAV       = $(BUILD_TOOLS_PATH)/aout2sav.rb
BMP_TO_RAW     = $(BUILD_TOOLS_PATH)/bmp_to_raw.rb
BUILD_DSK      = $(BUILD_TOOLS_PATH)/build_dsk.rb
FORMAT_LIST    = $(BUILD_TOOLS_PATH)/format_list.rb
LZSA3          = $(BUILD_TOOLS_PATH)/lzsa3
UPDATE_DISKMAP = $(BUILD_TOOLS_PATH)/update_disk_map.rb
# 2.38
MAKEFLAGS += --silent --jobs
LDFLAGS += --strip-all

INCS = -I../aku/uknc

.SUFFIXES:
.SUFFIXES: .s .o
.PHONY: clean

# --just-symbols= -R include only symbols from the file
# --print-map -M
# --strip-all -s

COMMON = defs.s ../aku/uknc/hwdefs.s ../aku/uknc/macros.s

all : pre-build dsk/timeCS.dsk

pre-build :
	mkdir -p build/clock1
	mkdir -p build/clock2
	mkdir -p build/clock3
	mkdir -p build/clock4

clean :
	rm -f build/*.lst
	rm -f build/*.o
	rm -f build/*.bin
	rm -f build/*.dsk

clean_all:
	rm -rf build/*

# timeCS.dsk ----------------------------------------------------------------{{{
dsk/timeCS.dsk : $(BUILD_DSK) \
		 $(BUILD_TOOLS_PATH)/dsk_image_constants.rb \
		 $(UPDATE_DISKMAP) \
		 dsk_flist \
		 build/bootsector.bin \
		 build/ppu_module.bin \
		 build/loader.bin \
		 build/title.bin \
		 build/player.bin \
		 build/clock1_screen.bin.lzsa3 \
		 build/clock2_screen.bin.lzsa3 \
		 build/clock3_screen.bin.lzsa3 \
		 build/clock4_screen.bin.lzsa3 \
		 build/song01.pt3.lzsa3 \
		 build/song02.pt3.lzsa3 \
		 build/song03.pt3.lzsa3 \
		 build/song04.pt3.lzsa3 \
		 build/song05.pt3.lzsa3 \
		 build/song06.pt3.lzsa3 \
		 build/song07.pt3.lzsa3 \
		 build/song08.pt3.lzsa3 \
		 build/song09.pt3.lzsa3 \
		 build/song10.pt3.lzsa3 \
		 build/song11.pt3.lzsa3 \
		 build/song12.pt3.lzsa3 \
		 build/song13.pt3.lzsa3 \
		 build/song14.pt3.lzsa3 \
		 build/song15.pt3.lzsa3 \
		 build/song16.pt3.lzsa3 \
		 build/song17.pt3.lzsa3 \
		 build/song18.pt3.lzsa3
	$(UPDATE_DISKMAP) dsk_flist build/title.map.txt build/title.bin -e 37264
	$(UPDATE_DISKMAP) dsk_flist build/player.map.txt build/player.bin -e 37264
	$(UPDATE_DISKMAP) dsk_flist build/bootsector.map.txt build/bootsector.bin
	$(BUILD_DSK) dsk_flist dsk/timeCS.dsk
# timeCS.dsk ----------------------------------------------------------------}}}

# bootsector.bin ------------------------------------------------------------{{{
build/bootsector.bin : build/bootsector.o \
                       build/loader.o \
                       build/player.o \
                       build/title.o \
                       build/ppu.o
	$(LD) $(LDFLAGS) -M \
		-T linker_scripts/bootsector.cmd \
		-R build/ppu.o > build/bootsector.map.txt
	chmod -x build/bootsector.bin

build/bootsector.o : $(COMMON) \
                     bootsector.s
	$(AS) $(INCS) -al bootsector.s -o build/bootsector.o | $(FORMAT_LIST)
# bootsector.bin ------------------------------------------------------------}}}

# ppu_module.bin ------------------------------------------------------------{{{
build/ppu_module.bin : build/ppu.o \
	               build/title.o
	$(LD) $(LDFLAGS) -T linker_scripts/ppu.cmd -R build/title.o
	ruby $(AOUT2SAV) build/ppu.out -b -s -o build/ppu_module.bin
build/ppu.o : $(COMMON) \
              ppu.s \
              ppu/interrupts_handlers.s \
              psgplayer.s \
              pt3play2.s
	$(AS) ppu.s $(INCS) -al -o build/ppu.o | $(FORMAT_LIST)
# ppu_module.bin ------------------------------------------------------------}}}

# loader.bin ----------------------------------------------------------------{{{
build/loader.bin : build/loader.o
	$(LD) $(LDFLAGS) build/loader.o -o build/loader.out
	ruby $(AOUT2SAV) build/loader.out -b -s -o build/loader.bin
build/loader.o : $(COMMON) \
               loader.s \
               build/c2ay_toyhifi.raw
	$(AS) loader.s $(INCS) -al -o build/loader.o | $(FORMAT_LIST)

build/c2ay_toyhifi.raw : $(BMP_TO_RAW) gfx/c2ay_toyhifi.bmp
	$(BMP_TO_RAW) gfx/c2ay_toyhifi.bmp build/c2ay_toyhifi.raw
# loader.bin ----------------------------------------------------------------}}}

# player.bin ----------------------------------------------------------------{{{
build/player.bin : build/player.o
	$(LD) $(LDFLAGS) -M build/player.o -o build/player.out > build/player.map.txt
	ruby $(AOUT2SAV) build/player.out -b -s -o build/player.bin
build/player.o : $(COMMON) \
               player.s \
               unlzsa3.s \
               unlzsa3_to_bp.s \
               unlzsa3_from_bp.s \
               build/loading.raw \
               build/error.raw \
               build/mainscr_piece.raw \
               build/mainscr.raw.lzsa \
               build/song_names.raw \
	       build/song01.pt3.lzsa3 \
	       build/song02.pt3.lzsa3 \
	       build/song03.pt3.lzsa3 \
	       build/song04.pt3.lzsa3 \
	       build/song05.pt3.lzsa3 \
	       build/song06.pt3.lzsa3 \
	       build/song07.pt3.lzsa3 \
	       build/song08.pt3.lzsa3 \
	       build/song09.pt3.lzsa3 \
	       build/song10.pt3.lzsa3 \
	       build/song11.pt3.lzsa3 \
	       build/song12.pt3.lzsa3 \
	       build/song13.pt3.lzsa3 \
	       build/song14.pt3.lzsa3 \
	       build/song15.pt3.lzsa3 \
	       build/song16.pt3.lzsa3 \
	       build/song17.pt3.lzsa3 \
	       build/song18.pt3.lzsa3
	$(AS) player.s $(INCS) -al -o build/player.o | $(FORMAT_LIST)
build/mainscr.raw.lzsa : build/mainscr.raw
	$(LZSA3) build/mainscr.raw build/mainscr.raw.lzsa
build/mainscr.raw : $(BMP_TO_RAW) gfx/mainscr.bmp
	$(BMP_TO_RAW) gfx/mainscr.bmp build/mainscr.raw
build/mainscr_piece.raw : $(BMP_TO_RAW) gfx/mainscr_piece.bmp
			  $(BMP_TO_RAW) gfx/mainscr_piece.bmp build/mainscr_piece.raw
build/loading.raw : $(BMP_TO_RAW) gfx/loading.bmp
	$(BMP_TO_RAW) gfx/loading.bmp build/loading.raw
build/error.raw : $(BMP_TO_RAW) gfx/error.bmp
	$(BMP_TO_RAW) gfx/error.bmp build/error.raw
build/song_names.raw: $(BMP_TO_RAW) gfx/song_names.bmp
	$(BMP_TO_RAW) -b 1 gfx/song_names.bmp build/song_names.raw
# player.bin ----------------------------------------------------------------}}}

# title.bin ----------------------------------------------------------------{{{
build/title.bin : build/title.o
	$(LD) $(LDFLAGS) -M build/title.o -o build/title.out > build/title.map.txt
	$(AOUT2SAV) build/title.out -b -s -o build/title.bin
build/title.o : $(COMMON) \
                title.s \
                unlzsa3.s \
		build/timecs_t.raw \
		build/timecs_t_mask.raw \
		build/timecs_i.raw \
		build/timecs_i_mask.raw \
		build/timecs_m.raw \
		build/timecs_m_mask.raw \
		build/timecs_e.raw \
		build/timecs_e_mask.raw \
		build/timecs_C.raw \
		build/timecs_C_mask.raw \
		build/timecs_S.raw \
		build/timecs_S_mask.raw \
		build/clockhand.raw \
		build/w3.raw.lzsa
	$(AS) title.s $(INCS) -al -o build/title.o | $(FORMAT_LIST)

build/w3.raw.lzsa : build/w3.raw
	$(LZSA3) build/w3.raw build/w3.raw.lzsa
build/w3.raw : $(BMP_TO_RAW) gfx/w3.bmp
	$(BMP_TO_RAW) gfx/w3.bmp build/w3.raw

build/timecs_t_mask.raw : $(BMP_TO_RAW) gfx/timecs_t_mask.bmp
	$(BMP_TO_RAW) gfx/timecs_t_mask.bmp build/timecs_t_mask.raw
build/timecs_i_mask.raw : $(BMP_TO_RAW) gfx/timecs_i_mask.bmp
	$(BMP_TO_RAW) gfx/timecs_i_mask.bmp build/timecs_i_mask.raw
build/timecs_m_mask.raw : $(BMP_TO_RAW) gfx/timecs_m_mask.bmp
	$(BMP_TO_RAW) gfx/timecs_m_mask.bmp build/timecs_m_mask.raw
build/timecs_e_mask.raw : $(BMP_TO_RAW) gfx/timecs_e_mask.bmp
	$(BMP_TO_RAW) gfx/timecs_e_mask.bmp build/timecs_e_mask.raw
build/timecs_C_mask.raw : $(BMP_TO_RAW) gfx/timecs_C_mask.bmp
	$(BMP_TO_RAW) gfx/timecs_C_mask.bmp build/timecs_C_mask.raw
build/timecs_S_mask.raw : $(BMP_TO_RAW) gfx/timecs_S_mask.bmp
	$(BMP_TO_RAW) gfx/timecs_S_mask.bmp build/timecs_S_mask.raw

build/timecs_t.raw : $(BMP_TO_RAW) gfx/timecs_t.bmp
	$(BMP_TO_RAW) -b 1 gfx/timecs_t.bmp build/timecs_t.raw
build/timecs_i.raw : $(BMP_TO_RAW) gfx/timecs_i.bmp
	$(BMP_TO_RAW) -b 1 gfx/timecs_i.bmp build/timecs_i.raw
build/timecs_m.raw : $(BMP_TO_RAW) gfx/timecs_m.bmp
	$(BMP_TO_RAW) -b 1 gfx/timecs_m.bmp build/timecs_m.raw
build/timecs_e.raw : $(BMP_TO_RAW) gfx/timecs_e.bmp
	$(BMP_TO_RAW) -b 1 gfx/timecs_e.bmp build/timecs_e.raw
build/timecs_C.raw : $(BMP_TO_RAW) gfx/timecs_C.bmp
	$(BMP_TO_RAW) -b 1 gfx/timecs_C.bmp build/timecs_C.raw
build/timecs_S.raw : $(BMP_TO_RAW) gfx/timecs_S.bmp
	$(BMP_TO_RAW) -b 1 gfx/timecs_S.bmp build/timecs_S.raw

build/clockhand.raw : $(BMP_TO_RAW) gfx/clockhand.bmp
	$(BMP_TO_RAW) -b 1 gfx/clockhand.bmp build/clockhand.raw

# title.bin -----------------------------------------------------------------}}}

clock_defs.s : build/player.o clock_start_update.rb
	./clock_start_update.rb
	touch clock_defs.s

# Songs: --------------------------------------------------------------------{{{
build/song01.pt3.lzsa3 : songs/12_b-AZuka.pt3
	$(LZSA3) songs/12_b-AZuka.pt3 build/song01.pt3.lzsa3

build/song02.pt3.lzsa3 : songs/03_dontgurgle_6ch.pt3
	$(LZSA3) songs/03_dontgurgle_6ch.pt3 build/song02.pt3.lzsa3

build/song03.pt3.lzsa3 : songs/04_wheelsinmotion_6ch.pt3
	$(LZSA3) songs/04_wheelsinmotion_6ch.pt3 build/song03.pt3.lzsa3

build/song04.pt3.lzsa3 : songs/06_roadagain_6ch.pt3
	$(LZSA3) songs/06_roadagain_6ch.pt3 build/song04.pt3.lzsa3

build/song05.pt3.lzsa3 : songs/07_inahurry_6ch.pt3
	$(LZSA3) songs/07_inahurry_6ch.pt3 build/song05.pt3.lzsa3

build/song06.pt3.lzsa3 : songs/08_laidpath_6ch.pt3
	$(LZSA3) songs/08_laidpath_6ch.pt3 build/song06.pt3.lzsa3

build/song07.pt3.lzsa3 : songs/09_walkedpast_6ch.pt3
	$(LZSA3) songs/09_walkedpast_6ch.pt3 build/song07.pt3.lzsa3

build/song08.pt3.lzsa3 : songs/10_notyetstar_6ch.pt3
	$(LZSA3) songs/10_notyetstar_6ch.pt3 build/song08.pt3.lzsa3

build/song09.pt3.lzsa3 : songs/11_freelane_6ch.pt3
	$(LZSA3) songs/11_freelane_6ch.pt3 build/song09.pt3.lzsa3

build/song10.pt3.lzsa3 : songs/14_markedmap_6ch.pt3
	$(LZSA3) songs/14_markedmap_6ch.pt3 build/song10.pt3.lzsa3

build/song11.pt3.lzsa3 : songs/15_waypooling_6ch.pt3
	$(LZSA3) songs/15_waypooling_6ch.pt3 build/song11.pt3.lzsa3

build/song12.pt3.lzsa3 : songs/16_eternaldreamer_6ch.pt3
	$(LZSA3) songs/16_eternaldreamer_6ch.pt3 build/song12.pt3.lzsa3

build/song13.pt3.lzsa3 : songs/17_distance6743_6ch.pt3
	$(LZSA3) songs/17_distance6743_6ch.pt3 build/song13.pt3.lzsa3

build/song14.pt3.lzsa3 : songs/18_freedomisnothing_6ch.pt3
	$(LZSA3) songs/18_freedomisnothing_6ch.pt3 build/song14.pt3.lzsa3

build/song15.pt3.lzsa3 : songs/19_escapingsilence_6ch.pt3
	$(LZSA3) songs/19_escapingsilence_6ch.pt3 build/song15.pt3.lzsa3

build/song16.pt3.lzsa3 : songs/20_cafeview_6ch.pt3
	$(LZSA3) songs/20_cafeview_6ch.pt3 build/song16.pt3.lzsa3

build/song17.pt3.lzsa3 : songs/21_openingdoors_6ch.pt3
	$(LZSA3) songs/21_openingdoors_6ch.pt3 build/song17.pt3.lzsa3

build/song18.pt3.lzsa3 : songs/22_fmradio_6ch.pt3
	$(LZSA3) songs/22_fmradio_6ch.pt3 build/song18.pt3.lzsa3
#----------------------------------------------------------------------------}}}

 # build/clock1_screen.bin -----------{{{
build/clock1_screen.bin.lzsa3 : build/clock1_screen.bin
	$(LZSA3) build/clock1_screen.bin build/clock1_screen.bin.lzsa3

build/clock1_screen.bin : build/clock1_screen.o \
			  build/player.o
	$(LD) $(LDFLAGS) build/clock1_screen.o -R build/player.o -o build/clock1_screen.out
	$(AOUT2SAV) build/clock1_screen.out -b -s -o build/clock1_screen.bin
build/clock1_screen.o : clock1_screen.s \
			$(COMMON) \
			clock_defs.s \
			build/clock1_gfx.bin
	$(AS) clock1_screen.s $(INCS) -al -o build/clock1_screen.o | $(FORMAT_LIST)

build/clock1_gfx.bin : build/clock1_gfx.o linker_scripts/bin.cmd
	$(LD) $(LDFLAGS) build/clock1_gfx.o -T linker_scripts/bin.cmd -o build/clock1_gfx.bin
build/clock1_gfx.o : clock1_gfx.s \
		     build/clock1/clock1.raw \
		     build/clock1/digits1.raw \
		     build/clock1/digit1_mask.raw \
		     build/clock1/digits1_shifted.raw \
		     build/clock1/digit1_shifted_mask.raw \
		     build/clock1/digits1_2.raw \
		     build/clock1/digits1_2_shifted.raw \
		     build/clock1/numbers1.raw \
		     build/clock1/circle1_left_off_0.raw \
		     build/clock1/circle1_left_off_1.raw \
		     build/clock1/circle1_left_off_2.raw \
		     build/clock1/circle1_left_off_3.raw \
		     build/clock1/circle1_left_off_4.raw \
		     build/clock1/circle1_left_off_5.raw \
		     build/clock1/circle1_left_off_6.raw \
		     build/clock1/circle1_left_off_7.raw \
		     build/clock1/circle1_left_on_0.raw \
		     build/clock1/circle1_left_on_1.raw \
		     build/clock1/circle1_left_on_2.raw \
		     build/clock1/circle1_left_on_3.raw \
		     build/clock1/circle1_left_on_4.raw \
		     build/clock1/circle1_left_on_5.raw \
		     build/clock1/circle1_left_on_6.raw \
		     build/clock1/circle1_left_on_7.raw \
		     build/clock1/circle1_right_off_0.raw \
		     build/clock1/circle1_right_off_1.raw \
		     build/clock1/circle1_right_off_2.raw \
		     build/clock1/circle1_right_off_3.raw \
		     build/clock1/circle1_right_off_4.raw \
		     build/clock1/circle1_right_off_5.raw \
		     build/clock1/circle1_right_off_6.raw \
		     build/clock1/circle1_right_off_7.raw \
		     build/clock1/circle1_right_on_0.raw \
		     build/clock1/circle1_right_on_1.raw \
		     build/clock1/circle1_right_on_2.raw \
		     build/clock1/circle1_right_on_3.raw \
		     build/clock1/circle1_right_on_4.raw \
		     build/clock1/circle1_right_on_5.raw \
		     build/clock1/circle1_right_on_6.raw \
		     build/clock1/circle1_right_on_7.raw
	$(AS) clock1_gfx.s $(INCS) -o build/clock1_gfx.o

build/clock1/clock1.raw : gfx/clock1/CLOCK1.bmp
	$(BMP_TO_RAW) gfx/clock1/CLOCK1.bmp build/clock1/clock1.raw
build/clock1/digits1.raw : gfx/clock1/digits1.bmp
	$(BMP_TO_RAW) gfx/clock1/digits1.bmp build/clock1/digits1.raw
build/clock1/digit1_mask.raw : gfx/clock1/digit1_mask.bmp
	$(BMP_TO_RAW) gfx/clock1/digit1_mask.bmp build/clock1/digit1_mask.raw
build/clock1/digits1_shifted.raw : gfx/clock1/digits1_shifted.bmp
	$(BMP_TO_RAW) gfx/clock1/digits1_shifted.bmp build/clock1/digits1_shifted.raw
build/clock1/digit1_shifted_mask.raw : gfx/clock1/digit1_shifted_mask.bmp
	$(BMP_TO_RAW) gfx/clock1/digit1_shifted_mask.bmp build/clock1/digit1_shifted_mask.raw
build/clock1/digits1_2.raw : gfx/clock1/digits1_2.bmp
	$(BMP_TO_RAW) gfx/clock1/digits1_2.bmp build/clock1/digits1_2.raw
build/clock1/digits1_2_shifted.raw : gfx/clock1/digits1_2_shifted.bmp
	$(BMP_TO_RAW) gfx/clock1/digits1_2_shifted.bmp build/clock1/digits1_2_shifted.raw
build/clock1/numbers1.raw : gfx/clock1/numbers1.bmp
	$(BMP_TO_RAW) gfx/clock1/numbers1.bmp build/clock1/numbers1.raw

build/clock1/circle1_left_off_0.raw : gfx/clock1/circle1_left_off_0.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_off_0.bmp build/clock1/circle1_left_off_0.raw
build/clock1/circle1_left_off_1.raw : gfx/clock1/circle1_left_off_1.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_off_1.bmp build/clock1/circle1_left_off_1.raw
build/clock1/circle1_left_off_2.raw : gfx/clock1/circle1_left_off_2.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_off_2.bmp build/clock1/circle1_left_off_2.raw
build/clock1/circle1_left_off_3.raw : gfx/clock1/circle1_left_off_3.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_off_3.bmp build/clock1/circle1_left_off_3.raw
build/clock1/circle1_left_off_4.raw : gfx/clock1/circle1_left_off_4.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_off_4.bmp build/clock1/circle1_left_off_4.raw
build/clock1/circle1_left_off_5.raw : gfx/clock1/circle1_left_off_5.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_off_5.bmp build/clock1/circle1_left_off_5.raw
build/clock1/circle1_left_off_6.raw : gfx/clock1/circle1_left_off_6.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_off_6.bmp build/clock1/circle1_left_off_6.raw
build/clock1/circle1_left_off_7.raw : gfx/clock1/circle1_left_off_7.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_off_7.bmp build/clock1/circle1_left_off_7.raw

build/clock1/circle1_left_on_0.raw : gfx/clock1/circle1_left_on_0.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_on_0.bmp build/clock1/circle1_left_on_0.raw
build/clock1/circle1_left_on_1.raw : gfx/clock1/circle1_left_on_1.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_on_1.bmp build/clock1/circle1_left_on_1.raw
build/clock1/circle1_left_on_2.raw : gfx/clock1/circle1_left_on_2.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_on_2.bmp build/clock1/circle1_left_on_2.raw
build/clock1/circle1_left_on_3.raw : gfx/clock1/circle1_left_on_3.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_on_3.bmp build/clock1/circle1_left_on_3.raw
build/clock1/circle1_left_on_4.raw : gfx/clock1/circle1_left_on_4.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_on_4.bmp build/clock1/circle1_left_on_4.raw
build/clock1/circle1_left_on_5.raw : gfx/clock1/circle1_left_on_5.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_on_5.bmp build/clock1/circle1_left_on_5.raw
build/clock1/circle1_left_on_6.raw : gfx/clock1/circle1_left_on_6.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_on_6.bmp build/clock1/circle1_left_on_6.raw
build/clock1/circle1_left_on_7.raw : gfx/clock1/circle1_left_on_7.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_left_on_7.bmp build/clock1/circle1_left_on_7.raw

build/clock1/circle1_right_off_0.raw : gfx/clock1/circle1_right_off_0.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_off_0.bmp build/clock1/circle1_right_off_0.raw
build/clock1/circle1_right_off_1.raw : gfx/clock1/circle1_right_off_1.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_off_1.bmp build/clock1/circle1_right_off_1.raw
build/clock1/circle1_right_off_2.raw : gfx/clock1/circle1_right_off_2.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_off_2.bmp build/clock1/circle1_right_off_2.raw
build/clock1/circle1_right_off_3.raw : gfx/clock1/circle1_right_off_3.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_off_3.bmp build/clock1/circle1_right_off_3.raw
build/clock1/circle1_right_off_4.raw : gfx/clock1/circle1_right_off_4.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_off_4.bmp build/clock1/circle1_right_off_4.raw
build/clock1/circle1_right_off_5.raw : gfx/clock1/circle1_right_off_5.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_off_5.bmp build/clock1/circle1_right_off_5.raw
build/clock1/circle1_right_off_6.raw : gfx/clock1/circle1_right_off_6.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_off_6.bmp build/clock1/circle1_right_off_6.raw
build/clock1/circle1_right_off_7.raw : gfx/clock1/circle1_right_off_7.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_off_7.bmp build/clock1/circle1_right_off_7.raw

build/clock1/circle1_right_on_0.raw : gfx/clock1/circle1_right_on_0.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_on_0.bmp build/clock1/circle1_right_on_0.raw
build/clock1/circle1_right_on_1.raw : gfx/clock1/circle1_right_on_1.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_on_1.bmp build/clock1/circle1_right_on_1.raw
build/clock1/circle1_right_on_2.raw : gfx/clock1/circle1_right_on_2.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_on_2.bmp build/clock1/circle1_right_on_2.raw
build/clock1/circle1_right_on_3.raw : gfx/clock1/circle1_right_on_3.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_on_3.bmp build/clock1/circle1_right_on_3.raw
build/clock1/circle1_right_on_4.raw : gfx/clock1/circle1_right_on_4.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_on_4.bmp build/clock1/circle1_right_on_4.raw
build/clock1/circle1_right_on_5.raw : gfx/clock1/circle1_right_on_5.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_on_5.bmp build/clock1/circle1_right_on_5.raw
build/clock1/circle1_right_on_6.raw : gfx/clock1/circle1_right_on_6.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_on_6.bmp build/clock1/circle1_right_on_6.raw
build/clock1/circle1_right_on_7.raw : gfx/clock1/circle1_right_on_7.bmp
	$(BMP_TO_RAW) gfx/clock1/circle1_right_on_7.bmp build/clock1/circle1_right_on_7.raw
#----------------------------------------------------------------------------}}}

 # build/clock2_screen.bin -----------{{{
build/clock2_screen.bin.lzsa3 : build/clock2_screen.bin
	$(LZSA3) build/clock2_screen.bin build/clock2_screen.bin.lzsa3

build/clock2_screen.bin : build/clock2_screen.o \
			  build/player.o
	$(LD) $(LDFLAGS) build/clock2_screen.o -R build/player.o -o build/clock2_screen.out
	$(AOUT2SAV) build/clock2_screen.out -b -s -o build/clock2_screen.bin
build/clock2_screen.o : clock2_screen.s \
			$(COMMON) \
			clock_defs.s \
			build/clock2/clock2.raw
	$(AS) clock2_screen.s $(INCS) -al -o build/clock2_screen.o | $(FORMAT_LIST)

build/clock2/clock2.raw : gfx/clock2/clock2.bmp
	$(BMP_TO_RAW) gfx/clock2/clock2.bmp build/clock2/clock2.raw
#----------------------------------------------------------------------------}}}

 # build/clock3_screen.bin -----------{{{
build/clock3_screen.bin.lzsa3 : build/clock3_screen.bin
	$(LZSA3) build/clock3_screen.bin build/clock3_screen.bin.lzsa3

build/clock3_screen.bin : build/clock3_screen.o \
			  build/player.o
	$(LD) $(LDFLAGS) build/clock3_screen.o -R build/player.o -o build/clock3_screen.out
	$(AOUT2SAV) build/clock3_screen.out -b -s -o build/clock3_screen.bin
build/clock3_screen.o : clock3_screen.s \
			$(COMMON) \
			clock_defs.s \
			build/clock3/clock3.raw \
			build/clock3/dangling1.raw \
			build/clock3/dangling2.raw
	$(AS) clock3_screen.s $(INCS) -al -o build/clock3_screen.o | $(FORMAT_LIST)

build/clock3/clock3.raw : gfx/clock3/clock3.bmp
	$(BMP_TO_RAW) gfx/clock3/clock3.bmp build/clock3/clock3.raw
build/clock3/dangling1.raw : gfx/clock3/dangling1.bmp
	$(BMP_TO_RAW) gfx/clock3/dangling1.bmp build/clock3/dangling1.raw
build/clock3/dangling2.raw : gfx/clock3/dangling2.bmp
	$(BMP_TO_RAW) gfx/clock3/dangling2.bmp build/clock3/dangling2.raw
#----------------------------------------------------------------------------}}}

 # build/clock4_screen.bin -----------{{{
build/clock4_screen.bin.lzsa3 : build/clock4_screen.bin
	$(LZSA3) build/clock4_screen.bin build/clock4_screen.bin.lzsa3

build/clock4_screen.bin : build/clock4_screen.o \
			  build/player.o
	$(LD) $(LDFLAGS) build/clock4_screen.o -R build/player.o -o build/clock4_screen.out
	$(AOUT2SAV) build/clock4_screen.out -b -s -o build/clock4_screen.bin
build/clock4_screen.o : clock4_screen.s \
			$(COMMON) \
			clock_defs.s \
			build/clock4/clock4.raw \
			build/clock4/digits.raw
	$(AS) clock4_screen.s $(INCS) -al -o build/clock4_screen.o | $(FORMAT_LIST)

build/clock4/clock4.raw : gfx/clock4/clock4.bmp
	$(BMP_TO_RAW) gfx/clock4/clock4.bmp build/clock4/clock4.raw
build/clock4/digits.raw : gfx/clock4/digits.bmp
	$(BMP_TO_RAW) gfx/clock4/digits.bmp build/clock4/digits.raw
#----------------------------------------------------------------------------}}}
