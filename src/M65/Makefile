# Builds the MEGA65 client with cc65 and (optionally) etherload/exomizer.
#
# Usage:
#   make            assemble + link -> test.prg
#   make run        build, then push to hardware via etherload
#   make dist       build a compressed, self-extracting distributable
#   make clean      remove build output
#
# Override tool locations if yours differ, e.g.:
#   make CA65="C:/cc65/bin/ca65.exe"

TASS      ?= C:/tools/64tass.exe
CA65      ?= C:/cc65/bin/ca65.exe
CL65      ?= C:/cc65/bin/cl65.exe
ETHERLOAD ?= etherload
EXOMIZER  ?= C:/tools/exomizer/win32/exomizer.exe

SRC      := test.s
OBJ      := test.o
CONFIG   := m65.cfg
PRG      := test.prg
DISTNAME := m65yhtze.prg
ETHSRC   := mega-ip/eth.asm
ETHSRCS  := $(wildcard mega-ip/*.asm)
ETHBIN   := eth.bin
ETHLST   := eth.lst
INCSRCS  := $(wildcard *.inc)

.PHONY: all run dist clean

all: $(PRG)

# test.s pulls this in via .incbin "eth.bin", so it must exist before ca65
# runs. Depends on every mega-ip/*.asm, not just eth.asm, since eth.asm
# includes the rest (arp/tcp/dhcp/etc.) - any of them changing should
# trigger a rebuild.
$(ETHBIN): $(ETHSRCS)
	"$(TASS)" $(ETHSRC) --nostart -L $(ETHLST) -o $(ETHBIN)

# test.s pulls in mouse.inc/common.inc/net.inc/error.inc etc. via
# .include, so any of them changing should trigger a rebuild too.
$(OBJ): $(SRC) $(ETHBIN) $(INCSRCS)
	"$(CA65)" $(SRC) -o $(OBJ)

$(PRG): $(OBJ) $(CONFIG)
	"$(CL65)" -t none --config $(CONFIG) $(OBJ) -o $(PRG)

run: all
	"$(ETHERLOAD)" -4 -r $(PRG)

dist: all
	"$(EXOMIZER)" sfx 0x080d -x 1 -t 65 -Di_ram_exit=0 -o $(DISTNAME) $(PRG)

clean:
	rm -f $(OBJ) $(PRG) $(DISTNAME) $(ETHBIN) $(ETHLST)
