partname=$(shell basename $(CURDIR))
program=out/a

DEBUG?=0
CC = m68k-amiga-elf-gcc
VASM = vasmm68k_mot
CCFLAGS = -g -MP -MMD -m68000 -Ofast -nostdlib -Wextra -Wno-unused-function -Wno-volatile-register-var -fomit-frame-pointer -fno-tree-loop-distribution -flto -fwhole-program -fno-exceptions
LDFLAGS = -Wl,--emit-relocs,-Ttext=0,-Map=$(program).map
VASMFLAGS = -m68000 -opt-fconst -nowarn=62 -x -DDEBUG=$(DEBUG)
FSUAE = fs-uae
FSUAEFLAGS = --hard_drive_0=./out --floppy_drive_0_sounds=off --video_sync=1 --automatic_input_grab=0
EXE2ADF = /home/torkildl/amiga/bin/exe2adf
SHRINKLER = /home/torkildl/amiga/bin/Shrinkler

exe = out/$(partname).exe
sources := $(wildcard src/*.asm)
elf_objects := $(addprefix obj/, $(patsubst %.asm,%.elf,$(notdir $(sources))))
elf_modules := $(filter-out obj/_main.elf,$(elf_objects))
deps := $(elf_objects:.elf=.d)

dist: all
	$(SHRINKLER) $(exe) out/$(partname)-shrink.exe
	$(EXE2ADF) -i out/$(partname)-shrink.exe -t decrunch.txt --label Talent -a out/$(partname).adf | grep -vE "^yes"

all: $(program).exe
	cp $(program).exe $(exe)

run: all
	echo sys:$(program).exe > out/s/startup-sequence
	$(FSUAE) $(FSUAEFLAGS)


$(program).exe: $(program).elf
	$(info Elf2Hunk $@)
	elf2hunk $< $@ -s
$(program).elf: $(elf_objects)
	$(info Linking $@)
	$(CC) $(CCFLAGS) $(LDFLAGS) obj/_main.elf $(elf_modules) -o $@
	m68k-amiga-elf-objdump --disassemble --no-show-raw-ins --visualize-jumps -S $@ >$(program).dasm.txt
$(elf_objects): obj/%.elf : src/%.asm $(data)
	$(info )
	$(info Assembling $<)
	$(VASM) $(VASMFLAGS) -Felf -dwarf=3 -o $@ $(CURDIR)/$<

clean:
	$(info Cleaning...)
	rm -f obj/* out/* 

-include $(deps)

$(deps): obj/%.d : src/%.asm
	$(info Building dependencies for $<)
	$(VASM) $(VASMFLAGS) -quiet -depend=make -o $(patsubst %.d,%.elf,$@) $(CURDIR)/$< > $@

.PHONY: all clean pre-build
