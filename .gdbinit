file build-x86_64/sysroot/usr/share/yak/kernel
target remote :1234
set substitute-path /base_dir/yak-src/ yak-src/
macro define offsetof(t, f) &((t *) 0)->f
