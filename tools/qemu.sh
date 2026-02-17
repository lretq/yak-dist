#!/bin/bash

usage() {
	echo "Usage: $0"
	exit 1
}

set -e

script_dir="$(dirname "$0")"
test -z "${script_dir}" && script_dir=.

source_dir="$(cd "${script_dir}"/.. && pwd -P)"
build_dir="$(pwd -P)"

case "$(basename "${build_dir}")" in
    build-x86_64) ARCH=x86_64 ;;
    build-riscv64) ARCH=riscv64 ;;
    *)
        echo "error: The build directory must be called 'build-<architecture>'." 1>&2
        exit 1
        ;;
esac

iso="yak-${ARCH}.iso"

native=0
enable_kvm=0
debug=0

qemu_args="${QEMU_OPTARGS}"
print_qemu_command=0

if [[ "${QEMU_PRINT}" -eq 1 ]]; then
	print_qemu_command=1
fi

while getopts "skPnGVD" optc; do 
	case "${optc}" in
		# enable [s]erial output
		s) qemu_args="$qemu_args -serial stdio" ;;
		# enable [k]vm
		k) enable_kvm=1 ;;
		# [P]ause before starting
		P) qemu_args="$qemu_args -S" ;;
		# add a [n]ic
		n) qemu_args="$qemu_args -netdev user,id=n1 -device e1000,netdev=n1" ;;
		# disable [G]raphics
		G) 
			qemu_args="$qemu_args -nographic"
			echo "---- Exit QEMU with Ctrl+A then X ----"
		;;
		D) debug=1 ;;
		# [V]erbose command
		V) print_qemu_command=1 ;;
		*) usage ;;
	esac
done

shift $((OPTIND-1))

if [ "$(uname -m)" = "$ARCH" ]; then
	native=1
fi

ovmf_file=ovmf.fd

ensure_ovmf() {
	if [[ ! -f "$ovmf_file" ]]; then
		echo "downloading ovmf for $ARCH ..."
		curl -Lo "edk2-ovmf.tar.xz" "https://github.com/osdev0/edk2-ovmf-nightly/releases/latest/download/edk2-ovmf.tar.xz"
		tar xvf edk2-ovmf.tar.xz
		cp "edk2-ovmf/ovmf-code-${ARCH}.fd" "$ovmf_file"
	fi
}

if [[ $debug -eq 1 ]]; then
	qemu_args="$qemu_args -d int -D qemulog.txt"
fi

case "$ARCH" in
x86_64)
        qemu_command="qemu-system-x86_64"
        qemu_mem="${QEMU_MEM:-512M}"
        qemu_cores="${QEMU_CORES:-2}"
        qemu_args="$qemu_args -M q35"
        qemu_args="$qemu_args -vga virtio"
        if [[ $debug -eq 1 ]]; then
            qemu_args="$qemu_args -M smm=off"
        fi
    	;;

*)
	echo "Arch unsupported by qemu.sh"
	exit 1
	;;
esac

if [[ "${QEMU_NO_KVM}" -eq 1 ]]; then
    enable_kvm=0
fi

if [[ $enable_kvm -eq 1 ]]; then
    if [[ $native -eq 1 ]]; then
        qemu_args="$qemu_args -accel kvm"
        if [ "$ARCH" = "x86_64" ]; then
            qemu_args="$qemu_args -cpu host,+invtsc"
        fi
    fi
fi

if [[ ! "${QEMU_NO_UEFI}" -eq 1 ]]; then
	ensure_ovmf
    	qemu_args="$qemu_args -drive if=pflash,unit=0,format=raw,file=$ovmf_file,readonly=on"
fi

qemu_args="$qemu_args -s -no-shutdown -no-reboot"
qemu_args="$qemu_args -cdrom ${iso}"
qemu_args="$qemu_args -smp $qemu_cores"
qemu_args="$qemu_args -m $qemu_mem"

if [[ $print_qemu_command -eq 1 ]]; then
    echo "${qemu_command} ${qemu_args}"
    exit
fi

${qemu_command} ${qemu_args}
