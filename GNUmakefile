NOMOD:=1
include common.mk

# common definitions
b_dir         = build
build_dir     = $(b_dir)
dist_dir      = dist
src_dir       = core

sdist         = $(name).$(version)

tc  ?= */*.t.rst

# common program specific definitions
version   = 0.2.0
name      = jm-util
sources   = GNUmakefile $(mods) README.rst

## install dependencies
i_deps    =
i_deps   += $(i_bin_dir)/
i_deps   += $(i_man_dir)/
i_deps   += $(bash_comp_dir)/ $(zsh_comp_dir)/
i_deps   += $(bash_comp_dir)/jm
i_deps   += $(zsh_comp_dir)/_jm
i_deps   += install_mods

mods = $(shell find -type f -name '.mod' -printf "%h\n")
recurse = printf "%s\n" $(mods) | xargs -I% $(MAKE) -C % $(1)

# build
.PHONY: build
build: .cargo_build

	$(call recurse,build)

.cargo_build: core/*.rs

	cargo build
	touch .cargo_build

.PHONY: install_mods
install_mods:

	printf "%s\n" $(mods) | xargs -I% $(MAKE) -C % install

.PHONY: install
install: $(i_deps)

# install completions
$(bash_comp_dir)/jm: completion/jm.bash

	$(install_data) $< $@

$(zsh_comp_dir)/_jm: completion/jm.bash

	$(install_data) $< $@

# source distribution archive
.PHONY: sdist
sdist:

	test ! -e $(dist_dir)/$(sdist)
	install -m700 -d $(dist_dir)/$(sdist)
	rsync -av $(sources) $(dist_dir)/$(sdist)
	cd $(dist_dir) && tar -cjf $(sdist).tar.bz2 $(sdist)

# tests
.PHONY: check
check: build

	$(call recurse,check)

# clean build/tests artefacts
.PHONY: clean
clean: clean-changelog

	$(RM) -r $(build_dir) $(dist_dir)

.PHONY: image
image:

	podman-compose build dev-base

.PHONY: check-deb
check-deb:

	debuild -i -us -uc -b

.PHONY: debuild
debuild:

	debuild -i -b

.PHONY: cp-packages
cp-packages:

	cd .. && { cp *.deb *.buildinfo *.build *.changes /out; ls -l /out/${name}*; }

.PHONY: version
version: # detect and write current version into sources

	git status
	zsh versionator/jm-versionator.zsh -dv --dch --output-shell core/jm_version.zsh

.PHONY: clean-changelog
clean-changelog:

	git checkout debian/changelog

.PHONY: build-pkg
packages: # Build debian package

	podman-compose run --rm debuild

.PHONY: release
release: # generate changelog, commit and tag it with ${version}

	zsh versionator/jm-versionator.zsh \
		-v --dch --output-shell core/jm_version.zsh ${version}
