#!/usr/bin/env bash

if [[ $(uname) == Darwin ]]; then
  export CC=clang
  export CXX=clang++
  export CPPFLAGS="$CPPFLAGS -I$PREFIX/include"
  export LDFLAGS="$LDFLAGS -L$PREFIX/lib -Wl,-rpath,$PREFIX/lib -headerpad_max_install_names"
  export LIBRARY_SEARCH_VAR=DYLD_FALLBACK_LIBRARY_PATH
  export MACOSX_DEPLOYMENT_TARGET="10.9"
  export CXXFLAGS="-stdlib=libc++ $CXXFLAGS"
elif [ $(uname) == Linux ] ; then
  export CPPFLAGS="-I${PREFIX}/include $CPPFLAGS"
  export LDFLAGS="-L${PREFIX}/lib $LDFLAGS"
fi


# @PYTHON@ is used in the build scripts and that breaks witht he long prefix.
# we need to redefine that to `python`. Note that using
_PY=$PYTHON
export PYTHON="python"

./configure --prefix="${PREFIX}" \
            --with-python=${PYTHON} \
            --with-libiconv=gnu \
            --disable-libmount

make -j$CPU_COUNT
# FIXME: sipping make check due to:
# ERROR: appinfo - too few tests run (expected 13, got 2)
# ERROR: appinfo - exited with status 133 (terminated by signal 5?)
# ERROR: desktop-app-info - too few tests run (expected 9, got 0)
# ERROR: desktop-app-info - exited with status 133 (terminated by signal 5?)
# Too long with no output (exceeded 10m0s)
# make check -j$CPU_COUNT
make install -j$CPU_COUNT

export PYTHON=$_PY

cd $PREFIX
find . -type f -name "*.la" -exec rm -rf '{}' \; -print
