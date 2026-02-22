#!/bin/bash

builddir=$(basename "$PWD")
arch=${builddir#build-}

case "$arch" in
	x86_64) ;;
	*) 
		echo "arch $arch unsupported"
		exit 1
	;;
esac


iso_root="$(mktemp -d)"
base="host-pkgs/limine/usr/local"
limine="${base}/share/limine"
iso_name="yak-$arch.iso"

mkdir -p "${iso_root}/boot"
cp -v sysroot/usr/share/yak/kernel "${iso_root}/boot/yak.elf"
cp -v sysroot/usr/share/yak/kernel.sym "${iso_root}/boot/yak.sym"
cp -v initrd.tar "${iso_root}/boot/initrd.tar"

mkdir -p "${iso_root}/boot/limine"

cat <<EOF > "${iso_root}/boot/limine/limine.conf"
timeout: 0

/Yak ($arch)
protocol: limine
kernel_path: boot():/boot/yak.elf
module_path: boot():/boot/initrd.tar
module_string: initrd
module_path: boot():/boot/yak.sym
module_string: symbols
EOF

mkdir -p "${iso_root}/EFI/BOOT/"

if [ "${arch}" = "x86_64" ]; then
	cp -v "${limine}/limine-bios.sys" \
	      "${limine}/limine-bios-cd.bin" \
	      "${limine}/limine-uefi-cd.bin" \
	      "${iso_root}/boot/limine/"

	cp -v "${limine}/BOOTX64.EFI" "${iso_root}/EFI/BOOT/"
	cp -v "${limine}/BOOTIA32.EFI" "${iso_root}/EFI/BOOT/"

	xorriso -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin \
        -no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus \
        -apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin \
        -efi-boot-part --efi-boot-image --protective-msdos-label \
        "${iso_root}" -o "${iso_name}"

	"${base}/bin/limine" bios-install "${iso_name}"
fi

rm -rf "${iso_root}"
