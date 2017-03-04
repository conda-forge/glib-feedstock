#!/usr/bin/env bash

# Need to get appropriate response to g_get_system_data_dirs()
# See the hardcoded-paths.patch file
export CFLAGS="-DCONDA_PREFIX=\\\"${PREFIX}\\\""

if [ "$(uname)" == "Darwin" ] ; then
  export CC=clang
  export CXX=clang++
  # Cf. the discussion in meta.yaml -- we require 10.7.
  export MACOSX_DEPLOYMENT_TARGET="10.7"
  SDK=/
  export CFLAGS="${CFLAGS} -isysroot ${SDK}"
  export LDFLAGS="${LDFLAGS} -Wl,-syslibroot,${SDK}"
  # Pick up the Conda version of gettext/libintl:
  export CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"
  export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib"
elif [ "$(uname)" == "Linux" ] ; then
  # Pick up the Conda version of gettext/libintl:
  export CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"
  export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"
fi

./configure --prefix=${PREFIX} \
            --with-python="${PYTHON}" \
            --with-libiconv=gnu \
            --disable-libmount \
                || { cat config.log; exit 1; }

make
# FIXME
# ERROR: fileutils - too few tests run (expected 15, got 14)
# ERROR: fileutils - exited with status 134 (terminated by signal 6?)
# make check
make install

rm -rf $PREFIX/share/gdb
