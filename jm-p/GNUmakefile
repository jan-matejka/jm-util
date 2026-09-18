include ../common.mk

check: dram_check

# p-c doubles as p-n/pc-c/pc-container/pc-n/pc-network -- it dispatches on
# its own invoked name ($0), so the rest are just symlinks to it.
build: p-aliases

.PHONY: p-aliases
p-aliases: $(b_bin_dir)/p-c

	ln -snf p-c $(b_bin_dir)/p-n
	ln -snf p-c $(b_bin_dir)/pc-c
	ln -snf p-c $(b_bin_dir)/pc-container
	ln -snf p-c $(b_bin_dir)/pc-n
	ln -snf p-c $(b_bin_dir)/pc-network

install: i-p-aliases

.PHONY: i-p-aliases
i-p-aliases: $(i_bin_dir)/p-c

	ln -snf p-c $(i_bin_dir)/p-n
	ln -snf p-c $(i_bin_dir)/pc-c
	ln -snf p-c $(i_bin_dir)/pc-container
	ln -snf p-c $(i_bin_dir)/pc-n
	ln -snf p-c $(i_bin_dir)/pc-network
