include ../common.mk

CXX ?= gcc
CPPFLAGS =-g -std=c++26 -Wall
LDLIBS ?= -lfmt

build: aliases

.PHONY: aliases
aliases: $(mod_b_deps)

	$(b_bin_dir)/jm-alias | xargs -I% ln -snf jm-alias $(b_bin_dir)/%

.PHONY: i_aliases
i_aliases:

	$(b_bin_dir)/jm-alias | xargs -I% ln -snf jm-alias $(i_bin_dir)/%

install: i_aliases
