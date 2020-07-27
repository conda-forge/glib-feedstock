@echo off
if defined GIO_MODULE_DIR (
	set "GIO_MODULE_DIR_CONDA_BACKUP=%GIO_MODULE_DIR%"
) else (
	set "GIO_MODULE_DIR_CONDA_BACKUP="
)
set "GIO_MODULE_DIR=%CONDA_PREFIX%\Library\lib\gio\modules"
