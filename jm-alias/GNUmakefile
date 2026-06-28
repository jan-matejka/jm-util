include ../common.mk

CXX ?= gcc
CPPFLAGS =-g -std=c++26 -Wall
LDLIBS ?= -lfmt

aliases=$(shell $(b_bin_dir)/jm-alias)
comps=$(patsubst %,$(b_zsh_comp_dir)/_%,$(aliases))

build: aliases $(comps)

.PHONY: aliases
aliases: $(b_bin_dir)/jm-alias

	$(b_bin_dir)/jm-alias | xargs -I% ln -snf jm-alias $(b_bin_dir)/%

.PHONY: i_aliases
i_aliases:

	$(b_bin_dir)/jm-alias | xargs -I% ln -snf jm-alias $(i_bin_dir)/%

install: i_aliases $(patsubst %,$(i_zsh_comp_dir)/_%,$(aliases))

$(b_zsh_comp_dir)/_%: $(b_zsh_comp_dir)

	$(b_bin_dir)/jm-alias --compdef $(patsubst _%,%,$(notdir $@)) >$@

$(b_bin_dir)/jm-alias: jm-alias.cpp

	$(CXX) $(CPPFLAGS) $(LDLIBS) $< -o $@
	$(MAKE) build # recurse to generate zsh completions

.PHONY: check
check: dram_check
