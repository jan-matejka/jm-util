.DEFAULT_GOAL := build
MAKEFLAGS:=-r
PERCENT:=%
tc  ?= *.t.rst

# common definitions
b_bin_dir     = $(b_dir)/bin
b_man1_dir     = $(b_dir)/man/man1
b_man_dir     = $(b_man1_dir)

prefix       ?= /usr/local

## installation targets
i_bin_dir     = $(DESTDIR)$(prefix)/bin
i_man_dir     = $(DESTDIR)$(prefix)/man/man1

install_bin   = install -m755
install_data  = install -m644

bash_comp_dir = $(DESTDIR)$(prefix)/share/bash-completion/completions
zsh_comp_dir  = $(DESTDIR)$(prefix)/share/zsh/vendor-completions

dirs      =
dirs     += $(b_bin_dir)/ $(i_bin_dir)/
dirs     += $(b_man_dir)/ $(i_man_dir)/
dirs     += $(bash_comp_dir)/ $(zsh_comp_dir)/

ifndef NOMOD
b_dir         = ../build
mod_cmds  =
mod_cmds += $(patsubst %.zsh,%,$(wildcard *.zsh))
mod_cmds += $(patsubst %.c,%,$(wildcard *.c))
mod_cmds += $(patsubst %.cpp,%,$(wildcard *.cpp))
mod_cmds += $(patsubst %.rs,%,$(wildcard *.rs))

mod_mans = $(patsubst %.rst,%,$(wildcard *.1.rst))

mod_b_deps += $(patsubst %,$(b_bin_dir)/%,$(mod_cmds))
mod_b_deps += $(patsubst %,$(b_man1_dir)/%,$(mod_mans))

i_deps =
i_deps += $(patsubst %,$(i_bin_dir)/%,$(mod_cmds))
i_deps += $(patsubst %,$(i_man_dir)/%,$(mod_mans))
endif

rs_native_build = ../target/debug/

.PHONY: help
help: ## Print help

	@@grep -h '^\([a-zA-Z$(PERCENT)_-]\+\):\($$\|[^=]\)' $(MAKEFILE_LIST) | \
		sort | \
		awk -F ':.*?## ' 'NF>=1 {printf "  %-26s%s\n", $$1, $$2}'

# build
.PHONY: build
build: $(mod_b_deps)

$(b_bin_dir)/%: %.cpp | $(b_bin_dir)/

	$(CXX) $(CPPFLAGS) $(LDLIBS) $< -o $@

$(b_bin_dir)/%: %.zsh | $(b_bin_dir)/

	$(install_bin) $< $@

$(b_bin_dir)/%: $(rs_native_build)/%

	install $< $@

# build man pages
$(b_man1_dir)/%: %.rst | $(b_man1_dir)/

	rst2man $< $@

# install binaries
$(i_bin_dir)/%: $(b_bin_dir)/% | $(i_bin_dir)/

	$(install_bin) $< $@

# install man pages
$(i_man_dir)/%: $(b_man_dir)/% | $(i_man_dir)/

	$(install_data) $< $@

# install
.PHONY: install
install: $(i_deps)

.PHONY: install-home
install-home:

	$(MAKE) install prefix=$(HOME)/.local

# install directories
%/:

	install -m755 -d $@

.PHONY: dram_check
dram_check:

	PATH=$$PWD/../build/bin:$$PATH dram -f -s zsh -t .t.rst $(tc)
