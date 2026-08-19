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

CA65      ?= C:/cc65/bin/ca65.exe
CL65      ?= C:/cc65/bin/cl65.exe
ETHERLOAD ?= etherload
EXOMIZER  ?= C:/tools/exomizer/win32/exomizer.exe

SRC      := test.s
OBJ      := test.o
CONFIG   := m65.cfg
PRG      := test.prg
DISTNAME := m65yhtze.prg

.PHONY: all run dist clean

all: $(PRG)

$(OBJ): $(SRC)
	"$(CA65)" $(SRC) -o $(OBJ)

$(PRG): $(OBJ) $(CONFIG)
	"$(CL65)" -t none --config $(CONFIG) $(OBJ) -o $(PRG)

run: all
	"$(ETHERLOAD)" -4 -r $(PRG)

dist: all
	"$(EXOMIZER)" sfx 0x080d -x 1 -t 65 -Di_ram_exit=0 -o $(DISTNAME) $(PRG)

clean:
	rm -f $(OBJ) $(PRG) $(DISTNAME)
