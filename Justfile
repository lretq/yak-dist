# may move to dotenv
arch := "x86_64"
jinx_dir := "build-" + arch

help:
	@echo "\t\t~~~ Yak-Dist ~~~"
	@echo " Setup your environment with 'just setup'."
	@echo " To regenerate the initrd, run 'just initrd iso'."
	@echo " Use 'just --list' to list other recipes."

setup:
	git clone --recursive https://github.com/lretq/yak-kernel yak-src
	git clone https://github.com/lretq/mlibc mlibc-src
	mkdir -p {{jinx_dir}}
	cd {{jinx_dir}} && \
	../jinx init ..	

host-build +PKGS:
	cd {{jinx_dir}} && \
	../jinx host-build {{PKGS}}

host-rebuild +PKGS:
	cd {{jinx_dir}} && \
	../jinx host-rebuild {{PKGS}}

pkg-build +PKGS:
	cd {{jinx_dir}} && \
	../jinx build {{PKGS}}

pkg-rebuild +PKGS:
	cd {{jinx_dir}} && \
	../jinx rebuild {{PKGS}}

pkg-regen +PKGS:
	cd {{jinx_dir}} && \
	../jinx regen {{PKGS}}

kernel:
	cd {{jinx_dir}} && \
	../jinx build yak

rebuild-kernel:
	cd {{jinx_dir}} && \
	../jinx rebuild yak

kernel-qemu: (pkg-build "yak" "mlibc") initrd iso qemu
	
distro:
	cd {{jinx_dir}} && \
	../jinx update base yak yak-init bash

initrd: distro
	cd {{jinx_dir}} && \
	rm -rf sysroot/ && \
	../jinx install sysroot/ base yak yak-init bash && \
	../tools/mkinitrd.sh sysroot/ initrd.tar

iso:
	cd {{jinx_dir}} && \
	../tools/mkiso.sh

qemu +ARGS='-sk':
	cd {{jinx_dir}} && \
	../tools/qemu.sh {{ARGS}} || true

qemu-gdb: (qemu '-skPD')

gdb:
	gdb -x '.gdbinit-{{arch}}'
