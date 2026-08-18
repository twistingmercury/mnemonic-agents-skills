#!/usr/bin/env bash

set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="${PROJ_ROOT:-$(cd "${SCRIPTS}/../.." && pwd)}"

AGENT_SOURCE="${AGENT_SOURCE:-${PROJ_ROOT}/codex/agents}"
AGENTS_DIR="${AGENTS_DIR:-${CODEX_HOME:-${HOME}/.codex}/agents/}"
FORCE="${FORCE:-0}"

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

    return 0
}

# Codex agent definitions may be grouped in arbitrarily nested directories.
# They are installed into one flat directory, so only their basenames matter.
list_repo_agent_files() {
    find "${AGENT_SOURCE}" -type f -name "*.toml" | sort
}

list_repo_agents() {
    local source_file

    while IFS= read -r source_file; do
        basename "${source_file}"
    done < <(list_repo_agent_files)
}

find_agent_source() {
    local agent_name="${1}"
    local source_file

    while IFS= read -r source_file; do
        if [ "$(basename "${source_file}")" = "${agent_name}" ]; then
            printf '%s\n' "${source_file}"
            return 0
        fi
    done < <(list_repo_agent_files)

    return 1
}

is_repo_managed_agent() {
    local agent_name="${1}"
    local source_agents="${2}"

    printf '%s\n' "${source_agents}" | grep -qxF "${agent_name}"
}

remove_repo_managed_agents() {
    local removed_count=0
    local preserved_count=0
    local source_agents
    source_agents="$(list_repo_agents)"

    if is_unsafe_agents_dir; then
        printf "ERROR: AGENTS_DIR is unsafe: '%s'\n" "${AGENTS_DIR}" >&2
        return 1
    fi

    if [ ! -d "${AGENTS_DIR}" ]; then
        return 0
    fi

    printf "Scanning existing agents...\n"

    for agent_file in "${AGENTS_DIR%/}"/*.toml; do
        local agent_name
        local expected_source

        if [ ! -e "${agent_file}" ] && [ ! -L "${agent_file}" ]; then
            continue
        fi

        agent_name="$(basename "${agent_file}")"

        if ! is_repo_managed_agent "${agent_name}" "${source_agents}"; then
            printf "  Preserving user agent: %s\n" "${agent_name}"
            preserved_count=$((preserved_count + 1))
            continue
        fi

        if [ ! -L "${agent_file}" ]; then
            printf "  Preserving existing non-symlink path: %s\n" "${agent_name}"
            preserved_count=$((preserved_count + 1))
            continue
        fi

        expected_source="$(find_agent_source "${agent_name}")"
        if [ "${FORCE}" != "1" ] && [ -e "${agent_file}" ] && [ "${agent_file}" -ef "${expected_source}" ]; then
            printf "  Keeping existing symlink: %s\n" "${agent_name}"
            preserved_count=$((preserved_count + 1))
            continue
        fi

        printf "  Removing repo agent: %s\n" "${agent_name}"
        if ! rm -f "${agent_file}"; then
            printf "ERROR: failed to remove agent: %s\n" "${agent_name}" >&2
            return 1
        fi
        removed_count=$((removed_count + 1))
    done

    printf "Removed %d repo agent(s), preserved %d existing agent(s)\n" "${removed_count}" "${preserved_count}"
    return 0
}

symlink_repo_agents() {
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
        local target_link
        agent_name="$(basename "${source_file}")"
        target_link="${AGENTS_DIR%/}/${agent_name}"

        if [ -L "${target_link}" ]; then
            printf "  Already installed (symlink exists): %s\n" "${agent_name}"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        if [ -e "${target_link}" ]; then
            printf "  Skipping existing non-symlink path: %s\n" "${agent_name}"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        if ! ln -s "${source_file}" "${target_link}"; then
            printf "ERROR: failed to install agent: %s\n" "${agent_name}" >&2
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

    if ! remove_repo_managed_agents; then
        printf "ERROR: failed to remove repo agents\n" >&2
        return 1
    fi

    if ! symlink_repo_agents; then
        printf "ERROR: failed to install repo agents\n" >&2
        return 1
    fi

    printf "\nSUCCESS: all agents updated\n"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_agents
fi
