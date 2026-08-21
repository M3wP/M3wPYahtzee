# Builds the M3wP Yahtzee! CLI server with lazbuild.
#
# Usage:
#   make                 build (default target)
#   make rebuild         force a full rebuild
#   make clean           remove build output
#   make run             build, then run the server
#
# If lazbuild isn't on your PATH, override LAZBUILD, e.g.:
#   make LAZBUILD=/usr/lib/lazarus/lazbuild
#
# The MEGA65 client lives in M65/ with its own Makefile (ca65/cl65, not
# lazbuild) - these targets just step in and build there, so both
# targets are reachable from the repo root without having to cd first:
#   make m65             build the client
#   make m65-run          build, then push to hardware via etherload
#   make m65-dist         build a compressed, self-extracting distributable
#   make m65-clean        remove client build output

ifeq ($(OS),Windows_NT)
LAZBUILD ?= G:/lazarus/lazbuild.exe
else
LAZBUILD ?= lazbuild
endif
PROJECT  := M3wPYahtzeeCLIServer.lpi
TARGET   := M3wPYahtzeeCLIServer

.PHONY: all build rebuild clean run m65 m65-run m65-dist m65-clean

all: build

build:
	"$(LAZBUILD)" "$(PROJECT)"

rebuild:
	"$(LAZBUILD)" -B "$(PROJECT)"

clean:
	rm -rf lib
	rm -f "$(TARGET)"

run: build
	./"$(TARGET)"

m65:
	$(MAKE) -C M65

m65-run:
	$(MAKE) -C M65 run

m65-dist:
	$(MAKE) -C M65 dist

m65-clean:
	$(MAKE) -C M65 clean
