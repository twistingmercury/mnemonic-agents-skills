#!/usr/bin/env bash

# Stage a regular file beside its destination, then replace the destination.
# Return 2 if staging cannot be created, or 1 if copying or renaming fails.
# Callers provide diagnostics and record ownership only after success.
materialize_file_copy() {
    local source_file="${1}"
    local target_file="${2}"
    local temporary_file

    if ! temporary_file="$(mktemp "${target_file}.tmp.XXXXXX")"; then
        return 2
    fi

    if ! rsync -a "${source_file}" "${temporary_file}" || ! mv -f "${temporary_file}" "${target_file}"; then
        rm -f "${temporary_file}"
        return 1
    fi

    return 0
}
