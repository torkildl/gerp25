#  -------- User-configurable options --------
#  Name of final executable (no extension by default)

OUT_NAME ?= demo

#  Where to put the final executable
OUT_DIR   ?= uae/dh0

#  Where to place intermediate object files
BUILD_DIR ?= build

#  Tool names (can be overridden)
VASM  = /home/torkildl/amiga/bin/vasmm68k_mot
VLINK  = /home/torkildl/amiga/bin/vlink


# -------- Project layout --------
SRC_DIR := src

# Only files directly under src/
SRCS := $(wildcard $(SRC_DIR)/*.asm)

# Map src/foo.asm -> build/foo.o
OBJS_ALL := $(patsubst $(SRC_DIR)/%.asm,$(BUILD_DIR)/%.o,$(SRCS))
#OBJS_ALL := $(patsubst %.asm,%.o,$(SRCS))
MAINOBJ  := $(BUILD_DIR)/_main.o
OBJS     := $(MAINOBJ) $(filter-out $(MAINOBJ),$(OBJS_ALL))





# Final output pat
OUT := $(OUT_DIR)/$(OUT_NAME)

# -------- Flags --------
# vasm: generate Amiga hunk object and include line debug info
VASMFLAGS ?= -m68000 -Fhunk -linedebug -w -quiet -Iinclude -Isrc
# vlink: produce Amiga hunk executable
VLINKFLAGS ?= -bamigahunk

# -------- Targets --------
.PHONY: build clean info
.DEFAULT_GOAL := build

build: clean $(OUT)

# Link step
$(OUT): $(OBJS) | $(OUT_DIR)
	$(VLINK) $(VLINKFLAGS) -o $@ $(OBJS) -e _start

# Assemble step
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm | $(BUILD_DIR)
	$(VASM) $(VASM_CPU) $(VASMFLAGS) -o $@ $<

# Create directories as needed
$(OUT_DIR):
	mkdir -p $@

$(BUILD_DIR):
	mkdir -p $@

# clean removes the build files and the executable
clean:
	rm -f $(BUILD_DIR)/* $(OUT)

info:
	@echo "SRCS: $(SRCS)"
	@echo "OBJS_ALL: $(OBJS_ALL)"
	@echo "OBJS: $(OBJS)"
	@echo "OUT : $(OUT)"
	@echo "VASM: $(VASM)"
	@echo "VLINK: $(VLINK)"
