#!/usr/bin/env bash

set -exuo pipefail

# There are a couple of places in the source that hardcode a system prefix;
# in hardcoded-paths.patch we edit them to refer to the Conda prefix so
# that they will get appropriately rewritten.
export CPPFLAGS="$CPPFLAGS -DCONDA_PREFIX=\\\"$PREFIX\\\""

# @PYTHON@ is used in the build scripts and that breaks with the long prefix.
# we need to redefine that to `python`.
export PYTHON="python"
unset _CONDA_PYTHON_SYSCONFIGDATA_NAME

mkdir -p forgebuild
cd forgebuild


# There is currently a cyclic dependency between glib and gobject-introspection:
# * https://discourse.gnome.org/t/dealing-with-glib-and-gobject-introspection-circular-dependency/18701
# * https://gitlab.gnome.org/GNOME/gobject-introspection/-/merge_requests/433
# * https://gitlab.gnome.org/GNOME/glib/-/issues/2616
conda create -p $(pwd)/g-ir-prefix -y g-ir-build-tools gobject-introspection

cat <<EOF > $BUILD_PREFIX/bin/g-ir-scanner
#!/bin/bash

exec $(pwd)/g-ir-prefix/bin/g-ir-scanner \$*
EOF
chmod +x $BUILD_PREFIX/bin/g-ir-scanner
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$(pwd)/g-ir-prefix/lib/pkgconfig"

if [[ "$target_platform" == "osx-arm64" && "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
    # TODO: create this in the compiler activation recipe
    echo "[host_machine]" > cross_file.txt
    echo "system = 'darwin'" >> cross_file.txt
    echo "cpu_family = 'aarch64'" >> cross_file.txt
    echo "cpu = 'arm64'" >> cross_file.txt
    echo "endian = 'little'" >> cross_file.txt
    MESON_ARGS="$MESON_ARGS --cross-file cross_file.txt"
    # TODO: do this in the compiler activation recipe as well
    export OBJC=$CC
    export OBJC_FOR_BUILD=$CC_FOR_BUILD
    export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config
elif [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
    # One of the tests uses objcopy to set up a special data file that can lead
    # to cross errors if we use the wrong program. Note that the way our setup
    # works, we actually pretend to Meson that we're doing a native build,
    # though.
    cat >machine_file.txt <<EOF
[binaries]
ld = '$LD'
objcopy = '$OBJCOPY'
EOF
    MESON_ARGS="$MESON_ARGS --native-file machine_file.txt"
fi

meson setup --buildtype=release --prefix="$PREFIX" --backend=ninja -Dlibdir=lib -Dlocalstatedir="$PREFIX/var" \
      -Dlibmount=disabled -Dselinux=disabled -Dxattr=false -Dnls=enabled -Dintrospection=enabled $MESON_ARGS .. \
      || { cat meson-logs/meson-log.txt ; exit 1 ; }

ninja -j${CPU_COUNT} -v

if [ "${target_platform}" == 'linux-aarch64' ] || [ "${target_platform}" == "linux-ppc64le" ]; then
    export MESON_TEST_TIMEOUT_MULTIPLIER=16
else
    export MESON_TEST_TIMEOUT_MULTIPLIER=2
fi

if [[ "$target_platform" != osx-* && "${CONDA_BUILD_CROSS_COMPILATION:-0}" != "1" ]] ; then  # too many tests fail on macOS
    # Disable this test as it fails if gdb is installed system-wide, otherwise it will be skipped.
    echo 'exit(0)' > ../glib/tests/assert-msg-test.py
    meson test --no-suite flaky --timeout-multiplier ${MESON_TEST_TIMEOUT_MULTIPLIER}
fi
