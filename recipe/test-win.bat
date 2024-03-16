@echo on

for /f "delims=" %%a in ('pkg-config --libs --msvc-syntax glib-2.0') do (
    %CC% /I "%LIBRARY_PREFIX%\include\glib-2.0" /I %LIBRARY_PREFIX%\lib\glib-2.0\include /Fe:output.exe test.c /link "%%a"
    if errorlevel 1 exit 1
)

output.exe
if errorlevel 1 exit 1
