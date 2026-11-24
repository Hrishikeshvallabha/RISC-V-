# ============================================================================
# Makefile: VeeR EL2 Bare-Metal RISC-V C Firmware
# Project:  Smart Temperature Monitoring and Fan Control SoC
# Target:   RV32IMC with Zicsr, 64 KiB Unified RAM (0x0000_0000)
#
# Standalone Source:
#   - temperature_fan_firmware.c (self-contained, no custom header dependencies)
#   - start.S (CRT0 bootstrap)
#   - temperature_fan.ld (linker script)
# ============================================================================

# Toolchain configuration (configurable via environment or command-line)
CROSS_COMPILE ?= riscv64-unknown-elf-
CC            := $(CROSS_COMPILE)gcc
OBJCOPY       := $(CROSS_COMPILE)objcopy
OBJDUMP       := $(CROSS_COMPILE)objdump
SIZE          := $(CROSS_COMPILE)size

# RISC-V Architecture and ABI Flags
# Target: RV32IMC + Zicsr, standard 32-bit integer ABI (ilp32), medium-low model
ARCH_FLAGS    := -march=rv32imc_zicsr -mabi=ilp32 -mcmodel=medlow

# Compiler Flags: Freestanding bare-metal environment, strict optimization and warnings
CFLAGS        := $(ARCH_FLAGS) -O2 -Wall -Wextra -ffreestanding -nostdlib -nostartfiles

# Linker Flags: Custom linker script, no standard startup libraries, garbage-collect unused sections
LDFLAGS       := -T temperature_fan.ld -nostdlib -nostartfiles -Wl,--gc-sections

# Source files (Standalone, NO custom header dependencies)
SRCS_S        := start.S
SRCS_C        := temperature_fan_firmware.c
OBJS          := $(SRCS_S:.S=.o) $(SRCS_C:.c=.o)

# Target artifact names
TARGET_BASE   := temperature_fan
TARGET_ELF    := $(TARGET_BASE).elf
TARGET_BIN    := $(TARGET_BASE).bin
TARGET_HEX    := $(TARGET_BASE).hex
TARGET_WORDS  := $(TARGET_BASE)_words.hex
TARGET_DIS    := $(TARGET_BASE).dis

.PHONY: all elf bin hex words_hex disassemble size clean help

# Default target builds complete artifact suite
all: elf bin hex words_hex disassemble size

# Link object files into ELF executable
elf: $(TARGET_ELF)

$(TARGET_ELF): $(OBJS) temperature_fan.ld
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@

# Assemble startup CRT0 assembly
%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

# Compile standalone C firmware (Zero custom header dependency)
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Flat binary generation
bin: $(TARGET_BIN)

$(TARGET_BIN): $(TARGET_ELF)
	$(OBJCOPY) -O binary $< $@

# Intel HEX image generation
hex: $(TARGET_HEX)

$(TARGET_HEX): $(TARGET_ELF)
	$(OBJCOPY) -O ihex $< $@

# Verilog 32-bit word-aligned memory hex generation (for $readmemh simulation preloads)
words_hex: $(TARGET_WORDS)

$(TARGET_WORDS): $(TARGET_ELF)
	$(OBJCOPY) -O verilog --verilog-data-width=4 $< $@

# Disassembly generation with source annotation
disassemble: $(TARGET_DIS)

$(TARGET_DIS): $(TARGET_ELF)
	$(OBJDUMP) -S -d $< > $@

# Report firmware section footprint and memory consumption
size: $(TARGET_ELF)
	@echo "=== Firmware Section Memory Usage ==="
	$(SIZE) $<

# Clean all generated build artifacts
clean:
	rm -f $(OBJS) $(TARGET_ELF) $(TARGET_BIN) $(TARGET_HEX) $(TARGET_WORDS) $(TARGET_DIS)

# Help target listing build options
help:
	@echo "VeeR EL2 Bare-Metal Firmware Build Targets:"
	@echo "  make              - Build ELF, BIN, HEX, words.hex, disassembly and report size"
	@echo "  make elf          - Build executable ELF"
	@echo "  make bin          - Generate flat binary image"
	@echo "  make hex          - Generate Intel HEX image"
	@echo "  make words_hex    - Generate Verilog 32-bit word-aligned hex image"
	@echo "  make disassemble  - Generate annotated assembly listing"
	@echo "  make size         - Report memory footprint"
	@echo "  make clean        - Remove generated build artifacts"
