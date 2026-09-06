#!/usr/bin/env bash

set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="${PROJ_ROOT:-$(cd "${SCRIPTS}/../.." && pwd)}"

AGENT_SOURCE="${AGENT_SOURCE:-${PROJ_ROOT}/codex/agents}"
CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
AGENTS_DIR="${AGENTS_DIR:-${CODEX_HOME:-${HOME}/.codex}/agents/}"

# shellcheck source=lib/managed_state.sh disable=SC1091
. "${SCRIPTS}/lib/managed_state.sh"

is_unsafe_agents_dir() {
    local resolved_dir

    if [ -z "${AGENTS_DIR}" ] || [ -z "${AGENTS_DIR//\//}" ]; then
        return 0
    fi

    # Also reject existing paths (including symlinks) that resolve to root.
    if [ -d "${AGENTS_DIR}" ]; then
        if ! resolved_dir="$(cd "${AGENTS_DIR}" && pwd -P)"; then
            return 0
        fi
        if [ "${resolved_dir}" = "/" ]; then
            return 0
        fi
    fi

    return 1
}

validate_environment() {
    if [ ! -d "${AGENT_SOURCE}" ]; then
        printf "ERROR: cannot locate the project's agent definitions directory: %s\n" "${AGENT_SOURCE}" >&2
        return 1
    fi

    if is_unsafe_agents_dir; then
        printf "ERROR: AGENTS_DIR is unsafe: '%s'\n" "${AGENTS_DIR}" >&2
        return 1
    fi

    if ! command -v rsync >/dev/null 2>&1; then
        printf "ERROR: rsync is required to materialize Codex agent definitions; install rsync and retry.\n" >&2
        return 1
    fi

    return 0
}

# Codex agent definitions may be grouped in arbitrarily nested directories.
# They are installed into one flat directory, so only their basenames matter.
list_repo_agent_files() {
    find "${AGENT_SOURCE}" -type f -name "*.toml" | sort
}

is_recognized_legacy_agent_link() {
    local link_target="${1}"
    local agent_name="${2}"
    local expected_source="${3}"

    if [ "${link_target}" = "${expected_source}" ]; then
        return 0
    fi

    case "${link_target}" in
        */codex/agents/*/"${agent_name}" | */codex/agents/"${agent_name}" | */agents/codex/*/"${agent_name}")
            return 0
            ;;
    esac
    return 1
}

materialize_agent() {
    local source_file="${1}"
    local target_file="${2}"
    local temporary_file

    if ! temporary_file="$(mktemp "${target_file}.tmp.XXXXXX")"; then
        printf "ERROR: failed to create temporary agent file: %s\n" "${target_file}" >&2
        return 1
    fi
    if ! rsync -a "${source_file}" "${temporary_file}" || ! mv -f "${temporary_file}" "${target_file}"; then
        rm -f "${temporary_file}"
        printf "ERROR: failed to materialize agent: %s\n" "$(basename "${source_file}")" >&2
        return 1
    fi
}

install_repo_agents() {
    local installed_count=0
    local skipped_count=0
    local source_file

    if is_unsafe_agents_dir; then
        printf "ERROR: AGENTS_DIR is unsafe: '%s'\n" "${AGENTS_DIR}" >&2
        return 1
    fi

    printf "Installing repo agents...\n"

    while IFS= read -r source_file; do
        local agent_name
        local target_file
        local managed_path
        local link_target
        agent_name="$(basename "${source_file}")"
        target_file="${AGENTS_DIR%/}/${agent_name}"
        managed_path="agents/${agent_name}"

        if [ -L "${target_file}" ]; then
            if ! link_target="$(readlink "${target_file}")"; then
                printf "ERROR: failed to read agent link: %s\n" "${target_file}" >&2
                return 1
            fi
            if ! is_recognized_legacy_agent_link "${link_target}" "${agent_name}" "${source_file}"; then
                printf "  Preserving unrelated symlink: %s\n" "${agent_name}"
                skipped_count=$((skipped_count + 1))
                continue
            fi
            if ! rm -f "${target_file}"; then
                printf "ERROR: failed to remove legacy agent link: %s\n" "${agent_name}" >&2
                return 1
            fi
        elif [ -e "${target_file}" ] && ! managed_state_is_managed "${managed_path}"; then
            printf "  Skipping existing non-symlink path: %s\n" "${agent_name}"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        if ! materialize_agent "${source_file}" "${target_file}"; then
            return 1
        fi
        if ! managed_state_mark "${managed_path}"; then
            return 1
        fi
        printf "  Installed: %s\n" "${agent_name}"
        installed_count=$((installed_count + 1))
    done < <(list_repo_agent_files)

    printf "Installed %d repo agent(s), skipped %d existing agent(s)\n" "${installed_count}" "${skipped_count}"
    return 0
}

install_agents() {
    if ! validate_environment; then
        return 1
    fi

    if [ ! -d "${AGENTS_DIR}" ]; then
        printf "Creating agents directory: %s\n" "${AGENTS_DIR}"
        if ! mkdir -p "${AGENTS_DIR}"; then
            printf "ERROR: failed to create agents directory: %s\n" "${AGENTS_DIR}" >&2
            return 1
        fi
    fi

    if ! install_repo_agents; then
        printf "ERROR: failed to install repo agents\n" >&2
        return 1
    fi

    printf "\nSUCCESS: all agents updated\n"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_agents
fi
