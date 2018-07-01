JC := julia
JFLAGS := -O3 --check-bounds=no --depwarn=no --procs auto

ifndef TRAVIS_JULIA_VERSION
	JFLAGS += --handle-signals=no
endif

SRCDIR := src
BINDIR := bin
MAIN := $(BINDIR)/main.jl
SCRIPT ?= scripts/mdl/12

ifneq ($(V),)
	SHELL := sh -x
	Q = true ||
endif


.PHONY: all debug interactive

all: $(SCRIPT)
	@$(Q)echo "  SCRIPT	$(SCRIPT)"
	@$(JC) $(JFLAGS) $(MAIN) $(SCRIPT)

interactive:
	@$(JC) $(JFLAGS) $(MAIN)

debug: JC := julia-debug
debug: all

