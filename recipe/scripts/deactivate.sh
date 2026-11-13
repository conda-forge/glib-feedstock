if [ -n "${XDG_DATA_DIRS_CONDA_BACKUP+x}" ]; then
    if [ -n "$XDG_DATA_DIRS_CONDA_BACKUP" ]; then
        export XDG_DATA_DIRS="$XDG_DATA_DIRS_CONDA_BACKUP"
    else
        unset XDG_DATA_DIRS
    fi
    unset XDG_DATA_DIRS_CONDA_BACKUP
fi
