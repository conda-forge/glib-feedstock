cd forgebuild
ninja install
if errorlevel 1 exit 1

del %LIBRARY_PREFIX%\bin\*.pdb
