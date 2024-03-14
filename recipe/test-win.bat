@echo on

for /f "delims=" %%a in ('pkg-config --cflags --libs glib-2.0') do (
    %CC% "%%a" /Fe:output.exe test.c 
    if errorlevel 1 exit 1
)

output.exe
if errorlevel 1 exit 1
