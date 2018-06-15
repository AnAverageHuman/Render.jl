JC := julia
JFLAGS := -O3 --check-bounds=no --depwarn=no --procs auto

ifndef TRAVIS_JULIA_VERSION
	JFLAGS += --handle-signals=no
endif

SRCDIR := src
BINDIR := bin
MAIN := $(BINDIR)/main.jl
SCRIPT ?= scripts/12

RDEPS := https://github.com/JuliaLang/JuliaParser.jl

ifneq ($(V),)
	SHELL := sh -x
	Q = true ||
endif


.PHONY: all debug deps

all: deps $(SCRIPT)
	@$(Q)echo "  SCRIPT	$(SCRIPT)"
	@$(JC) $(JFLAGS) $(MAIN) $(SCRIPT)

debug: JC := julia-debug
debug: all

deps:
	-@$(foreach pkg, $(RDEPS), $(Q)echo "  DEPENDENCY	$(pkg)"; julia $(JFLAGS) -e 'Pkg.clone("$(pkg)")')

