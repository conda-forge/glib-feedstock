cd forgebuild
ninja install
if errorlevel 1 exit 1

if NOT [%PKG_NAME%] == [glib] (
  if [%PKG_NAME%] == [libglib] (
      del %LIBRARY_PREFIX%\bin\gio-querymodules.exe
      if errorlevel 1 exit 1
      del %LIBRARY_PREFIX%\bin\gio.exe
      if errorlevel 1 exit 1
      del %LIBRARY_PREFIX%\bin\glib-compile-resources.exe
      if errorlevel 1 exit 1
      del %LIBRARY_PREFIX%\bin\glib-compile-schemas.exe
      if errorlevel 1 exit 1
      del %LIBRARY_PREFIX%\share\bash-completion\completions\gio
      if errorlevel 1 exit 1
  )
  del %LIBRARY_PREFIX%\bin\gdbus-codegen
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\bin\gdbus.exe
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\bin\glib-genmarshal
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\bin\glib-gettextsize
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\bin\glib-mkenums
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\bin\gobject-query
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\bin\gresource.exe
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\bin\gsettings.exe
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\bin\gspawn*
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\bin\gtester*
  if errorlevel 1 exit 1

  del %LIBRARY_PREFIX%\include\glib*
  if errorlevel 1 exit 1

  del %LIBRARY_PREFIX%\lib\pkgconfig\gio*
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\lib\pkgconfig\glib*
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\lib\pkgconfig\gmodule*
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\lib\pkgconfig\gobject*
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\lib\pkgconfig\gthread*
  if errorlevel 1 exit 1

  del %LIBRARY_PREFIX%\share\bash-completion\completions\gapplication
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\share\bash-completion\completions\gdbus
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\share\bash-completion\completions\gresource
  if errorlevel 1 exit 1
  del %LIBRARY_PREFIX%\share\bash-completion\completions\gsettings
  if errorlevel 1 exit 1
)

del %LIBRARY_PREFIX%\bin\*.pdb
