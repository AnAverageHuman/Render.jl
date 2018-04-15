JC := julia
JFLAGS := -O3 --handle-signals=no --check-bounds=no --depwarn=error

SRCDIR := src
MAIN := $(SRCDIR)/main.jl
SCRIPT ?= scripts/08

ifneq ($(V),)
	SHELL := sh -x
	Q = true ||
endif


.PHONY: all debug

all: $(SCRIPT)
	@$(Q)echo "  SCRIPT		$<"
	@$(JC) $(JFLAGS) $(MAIN) $(SCRIPT)

debug: JC := julia-debug
debug: all

