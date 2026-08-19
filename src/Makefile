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

ifeq ($(OS),Windows_NT)
LAZBUILD ?= G:/lazarus/lazbuild.exe
else
LAZBUILD ?= lazbuild
endif
PROJECT  := M3wPYahtzeeCLIServer.lpi
TARGET   := M3wPYahtzeeCLIServer

.PHONY: all build rebuild clean run

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
