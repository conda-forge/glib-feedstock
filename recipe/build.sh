#!/usr/bin/env bash

set -exuo pipefail

meson_config_args=(
     --backend=ninja
     -Dlibdir=lib
     -Dlibmount=disabled
     -Dselinux=disabled
     -Dxattr=false
     -Dnls=enabled
     -Dglib_debug=disabled
)

# There are a couple of places in the source that hardcode a system prefix;
# in hardcoded-paths.patch we edit them to refer to the Conda prefix so
# that they will get appropriately rewritten.
export CPPFLAGS="$CPPFLAGS -DCONDA_PREFIX=\\\"$PREFIX\\\""

# @PYTHON@ is used in the build scripts and that breaks with the long prefix.
# we need to redefine that to `python`.
export PYTHON="python"
unset _CONDA_PYTHON_SYSCONFIGDATA_NAME

# There is currently a cyclic dependency between glib and gobject-introspection:
#
# * https://discourse.gnome.org/t/dealing-with-glib-and-gobject-introspection-circular-dependency/18701
# * https://gitlab.gnome.org/GNOME/gobject-introspection/-/merge_requests/433
# * https://gitlab.gnome.org/GNOME/glib/-/issues/2616
#
# If we were doing this build in isolation, we'd have to build glib without
# introspection, then build gobject-introspection against that glib, then
# rebuild glib *with* introspection. But because we're plugged into the Conda
# ecosystem, we can save some effort by installing an existing
# gobject-introspection package (which depends on an existing glib package) in a
# separate environment.
#
# The g-ir-scanner tool needs to be able to execute our compilers, so we have to
# do some work to be able to run it inside the current build environment even
# though it is installed into a different environment.
#
# Note: the `libgirepository` package built in the gobject-introspection
# feedstock provides the `libgirepository-1.0` library. Our `libglib` output
# package now provides `libgirepository-2.0`. This is a necessary part of the
# effort to break the dependency cycle but is certainly confusing.

export GIR_PREFIX=$(pwd)/g-ir-prefix

conda create -p ${GIR_PREFIX} -y g-ir-build-tools gobject-introspection

# We don't want to add the GIR environment entirely to our path, to avoid
# confusing our build environment, but g-ir-scanner needs to be findable, and it
# needs to be launched by its own Python interpreter. So we need a wrapper
# script.
cat <<EOF >$BUILD_PREFIX/bin/g-ir-scanner
#!/bin/bash
exec ${GIR_PREFIX}/bin/python3 ${GIR_PREFIX}/bin/g-ir-scanner "\$@"
EOF
chmod +x $BUILD_PREFIX/bin/g-ir-scanner

# Ensure that pkg-config checks for gobject-introspection-1.0 will work.
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:${GIR_PREFIX}/lib/pkgconfig"

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == 1 ]]; then
  unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
  (
    export CC=$CC_FOR_BUILD
    export CXX=$CXX_FOR_BUILD
    if [[ "${target_platform}" == osx-* ]]; then
      export OBJC=$OBJC_FOR_BUILD
    fi
    export AR="$($CC_FOR_BUILD -print-prog-name=ar)"
    export NM="$($CC_FOR_BUILD -print-prog-name=nm)"
    export OBJCOPY="$($CC_FOR_BUILD -print-prog-name=objcopy)"
    export LDFLAGS="${LDFLAGS//$PREFIX/$BUILD_PREFIX} -liconv"
    export PKG_CONFIG_PATH="${BUILD_PREFIX}/lib/pkgconfig:${GIR_PREFIX}/lib/pkgconfig"

    # Unset them as we're ok with builds that are either slow or non-portable
    unset CFLAGS
    unset CXXFLAGS
    export CPPFLAGS="-isystem $BUILD_PREFIX/include -DCONDA_PREFIX=\\\"$BUILD_PREFIX\\\""
    export host_alias=$build_alias

    meson setup native-build \
        "${meson_config_args[@]}" \
        --prefix="$BUILD_PREFIX" \
        -Dintrospection=enabled \
        -Dlocalstatedir="$BUILD_PREFIX/var" \
        || { cat native-build/meson-logs/meson-log.txt ; exit 1 ; }

    # This script would generate the functions.txt and dump.xml and save them
    # This is loaded in the native build. We assume that the functions exported
    # by glib are the same for the native and cross builds
    export GI_CROSS_LAUNCHER=$GIR_PREFIX/libexec/gi-cross-launcher-save.sh
    ninja -C native-build -j${CPU_COUNT}
    ninja -C native-build install

    # Store generated introspection information
    mkdir -p introspection/lib
    cp -ap $BUILD_PREFIX/lib/girepository-1.0 introspection/lib
    mkdir -p introspection/share
    cp -ap $BUILD_PREFIX/share/gir-1.0 introspection/share
  )
  export GI_CROSS_LAUNCHER=$GIR_PREFIX/libexec/gi-cross-launcher-load.sh
  export MESON_ARGS="${MESON_ARGS} -Dintrospection=disabled"
else
  export MESON_ARGS="${MESON_ARGS} -Dintrospection=enabled"
fi

meson setup builddir \
    ${MESON_ARGS} \
    "${meson_config_args[@]}" \
    --prefix="$PREFIX" \
    -Dlocalstatedir="$PREFIX/var" \
    || { cat builddir/meson-logs/meson-log.txt ; exit 1 ; }

ninja -C builddir -j${CPU_COUNT} -v

if [ "${target_platform}" == 'linux-aarch64' ] || [ "${target_platform}" == "linux-ppc64le" ]; then
    export MESON_TEST_TIMEOUT_MULTIPLIER=16
else
    export MESON_TEST_TIMEOUT_MULTIPLIER=2
fi

if [[ "$target_platform" != osx-* && "${CONDA_BUILD_CROSS_COMPILATION:-0}" != "1" ]] ; then  # too many tests fail on macOS
    # Disable this test as it fails if gdb is installed system-wide, otherwise it will be skipped.
    echo 'exit(0)' > glib/tests/assert-msg-test.py
    pushd builddir
    meson test --no-suite flaky --timeout-multiplier ${MESON_TEST_TIMEOUT_MULTIPLIER}
    popd
fi
