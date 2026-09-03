#!/usr/bin/env bash

# State helpers shared by the Codex installation phases.  Paths are recorded
# relative to CODEX_HOME, so only an explicitly recorded installed path may be
# refreshed on a later run.

MANAGED_STATE_DIR="${CODEX_HOME}/.mnemonic-agents-skills"
MANAGED_STATE_FILE="${MANAGED_STATE_DIR}/managed-paths"

managed_state_validate_path() {
    local managed_path="${1}"

    case "${managed_path}" in
        "" | /* | */../* | ../* | */..)
            return 1
            ;;
    esac
    return 0
}

managed_state_is_managed() {
    local managed_path="${1}"

    managed_state_validate_path "${managed_path}" || return 1
    [ -f "${MANAGED_STATE_FILE}" ] && grep -qxF "${managed_path}" "${MANAGED_STATE_FILE}"
}

managed_state_mark() {
    local managed_path="${1}"
    local state_tmp

    if ! managed_state_validate_path "${managed_path}"; then
        printf "ERROR: refusing unsafe managed path: %s\n" "${managed_path}" >&2
        return 1
    fi

    if ! mkdir -p "${MANAGED_STATE_DIR}"; then
        printf "ERROR: failed to create installer state directory: %s\n" "${MANAGED_STATE_DIR}" >&2
        return 1
    fi

    if managed_state_is_managed "${managed_path}"; then
        return 0
    fi

    if ! state_tmp="$(mktemp "${MANAGED_STATE_FILE}.tmp.XXXXXX")"; then
        printf "ERROR: failed to create installer state file\n" >&2
        return 1
    fi

    if [ -f "${MANAGED_STATE_FILE}" ]; then
        if ! cat "${MANAGED_STATE_FILE}" > "${state_tmp}"; then
            rm -f "${state_tmp}"
            return 1
        fi
    fi
    if ! printf '%s\n' "${managed_path}" >> "${state_tmp}" || ! mv -f "${state_tmp}" "${MANAGED_STATE_FILE}"; then
        rm -f "${state_tmp}"
        printf "ERROR: failed to update installer state\n" >&2
        return 1
    fi
}
