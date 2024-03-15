@echo on

for /f "delims=" %%a in ('pkg-config --libs --msvc-syntax glib-2.0') do (
    %CC% "%%a" /I "%LIBRARY_PREFIX%\include" /Fe:output.exe test.c
    if errorlevel 1 exit 1
)

output.exe
if errorlevel 1 exit 1
