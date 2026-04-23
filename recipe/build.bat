@ECHO ON

set "GIR_PREFIX=%cd%\g-ir-prefix"

@REM See `build.sh` for a general description of how we handle the circular
@REM dependency between glib and gobject-introspection.
call conda create --console=classic -p %GIR_PREFIX% -y -c conda-forge g-ir-build-tools gobject-introspection glib
if errorlevel 1 exit 1

@REM As on Linux/Mac, we need to make sure that g-ir-scanner is invoked by the Python
@REM interpreter associated with its environment. Our approach here is to replace
@REM the pure-Python script with a simple batch wrapper.
ren %GIR_PREFIX%\Library\bin\g-ir-scanner g-ir-scanner.py
if errorlevel 1 exit 1

@REM `%%^*` works out to `%*` in the final batch file, which forwards the input arguments
echo %GIR_PREFIX%\python.exe %GIR_PREFIX%\Library\bin\g-ir-scanner.py %%^* >%GIR_PREFIX%\Library\bin\g-ir-scanner.bat
if errorlevel 1 exit 1

set "PATH=%PATH%;%GIR_PREFIX%\Library;%GIR_PREFIX%\Library\bin"

mkdir forgebuild
cd forgebuild

@REM Find libffi with pkg-config
FOR /F "delims=" %%i IN ('cygpath.exe -m "%LIBRARY_PREFIX%"') DO set "LIBRARY_PREFIX_M=%%i"
FOR /F "delims=" %%i IN ('cygpath.exe -m "%GIR_PREFIX%"') DO set "GIR_PREFIX_M=%%i"
set PKG_CONFIG_PATH=%LIBRARY_PREFIX_M%/lib/pkgconfig;%LIBRARY_PREFIX_M%/share/pkgconfig;%GIR_PREFIX_M%/Library/lib/pkgconfig

@REM Avoid a Meson issue - https://github.com/mesonbuild/meson/issues/4827
set "PYTHONLEGACYWINDOWSSTDIO=1"
set "PYTHONIOENCODING=UTF-8"

@REM See hardcoded-paths.patch
set "CPPFLAGS=%CPPFLAGS% -D^"%LIBRARY_PREFIX_M%^""

meson setup --buildtype=release --prefix=%LIBRARY_PREFIX_M% --backend=ninja -Dselinux=disabled -Dxattr=false -Dlibmount=disabled -Dnls=enabled -Dglib_debug=disabled -Dintrospection=enabled ..
if errorlevel 1 exit 1

ninja
if errorlevel 1 exit 1

@REM Lots of tests fail right now
@REM ninja test
@REM if errorlevel 1 exit 1
