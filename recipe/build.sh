#!/usr/bin/env bash

if [[ ${HOST} =~ .*darwin.* ]]; then
    LIBICONV=gnu
    # Need to get appropriate response to g_get_system_data_dirs()
    # See the hardcoded-paths.patch file
    export CFLAGS="$CFLAGS -I$PREFIX/include -DCONDA_PREFIX=\\\"${PREFIX}\\\""
    export CPPFLAGS="${CPPFLAGS} -I${PREFIX}/include"
    export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib"
elif [[ ${HOST} =~ .*linux.* ]]; then
    # So the system (builtin to glibc) iconv gets found and used.
    LIBICONV=maybe
    export PATH="$PATH:$PREFIX/$HOST/sysroot/usr/bin"
fi

autoreconf -vfi

# A full path to PYTHON causes overly long shebang in gobject/glib-genmarshal
./configure --prefix=${PREFIX} \
            --host=$HOST \
            --with-python=$(basename "${PYTHON}") \
            --with-libiconv=${LIBICONV} \
            --disable-libmount \
                || { cat config.log; exit 1; }

make -j${CPU_COUNT} ${VERBOSE_AT}
if [[ ! ${HOST} =~ .*darwin.* ]] && [[ ! ${HOST} =~ .*linux.* ]]; then
  # On c3i these fail:
  # ERROR: fileutils - Bail out! GLib:ERROR:fileutils.c:899:test_stdio_wrappers: assertion failed (errno == EACCES): (2 == 13)
  # ERROR: gdatetime - Bail out! GLib:ERROR:gdatetime.c:2000:test_GDateTime_strftime_error_handling: assertion failed (p == (((void*)0))): ("11:00:00 PM" == NULL)
  make check
fi
make install

# gdb folder has a nested folder structure similar to our host prefix (255 chars) which causes installation issues
#    so kill it.
rm -rf $PREFIX/share/gdb
