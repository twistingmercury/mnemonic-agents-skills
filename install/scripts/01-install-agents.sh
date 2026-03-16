#!/usr/bin/env bash

set -e

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
SETUP_DIR="${SETUP_DIR:-$(cd "${SCRIPTS}/.." && pwd)}"
PROJ_ROOT="${PROJ_ROOT:-$(cd "${SETUP_DIR}/.." && pwd)}"

# Logging setup
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"
LOG_DIR="${SCRIPTS}/logs/${TIMESTAMP}"
LOG_FILE="${LOG_DIR}/01-install-agents.log"

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1

printf "Logging to: %s\n" "${LOG_FILE}"

AGENT_SOURCE="${PROJ_ROOT}/agents"
AGENTS_DIR="${HOME}/.claude/agents/"

validate_environment() {
    if [ ! -d "${AGENT_SOURCE}" ]; then
        printf "ERROR: cannot locate the projects agent definitions directory: %s\n" "${AGENT_SOURCE}" >&2
        return 1
    fi

    return 0
}

# Build a list of agent basenames from the source directory.
# An agent is any .md file in a subdirectory of agents/ (excludes top-level files
# like ABOUT-THE-AGENTS.md).
list_repo_agents() {
    find "${AGENT_SOURCE}" -mindepth 2 -type f -name "*.md" -not -path "*/commands/*" -exec basename {} \;
}


# Check if an agent basename exists in the repo's source list.
# "Repo-managed agent" = from this repo; "user agent" = manually created in ~/.claude/agents/.
# Used during removal to preserve user agents and only replace repo-managed ones.
is_repo_managed_agent() {
    local agent_basename="${1}"
    local source_agents="${2}"

    printf '%s\n' "${source_agents}" | grep -qxF "${agent_basename}"
}

remove_repo_managed_agents() {
    local removed_count=0
    local preserved_count=0
    local source_agents
    source_agents="$(list_repo_agents)"

    if [ ! -d "${AGENTS_DIR}" ]; then
        return 0
    fi

    printf "Scanning existing agents...\n"

    for agent_file in "${AGENTS_DIR}"/*.md; do
        if [ ! -f "${agent_file}" ] && [ ! -L "${agent_file}" ]; then
            continue
        fi

        local agent_name
        local expected_source
        agent_name="$(basename "${agent_file}")"
        expected_source="$(find "${AGENT_SOURCE}" -mindepth 2 -type f -name "${agent_name}" -not -path "*/commands/*" | head -n 1)"

        if is_repo_managed_agent "${agent_name}" "${source_agents}"; then
            if [ -L "${agent_file}" ] && [ -n "${expected_source}" ]; then
                if [ "$(readlink "${agent_file}")" = "${expected_source}" ]; then
                    printf "  Keeping existing symlink: %s\n" "${agent_name}"
                    preserved_count=$((preserved_count + 1))
                    continue
                fi
            fi

            printf "  Removing repo agent: %s\n" "${agent_name}"
            rm -f "${agent_file}"
            removed_count=$((removed_count + 1))
        else
            printf "  Preserving user agent: %s\n" "${agent_name}"
            preserved_count=$((preserved_count + 1))
        fi
    done

    printf "Removed %d repo agent(s), preserved %d user agent(s)\n" "${removed_count}" "${preserved_count}"
    return 0
}

symlink_repo_agents() {
    local installed_count=0
    local skipped_count=0

    printf "Installing repo agents from %s...\n" "${AGENT_SOURCE}"

    while IFS= read -r source_file; do
        local agent_name
        local target_link
        agent_name="$(basename "${source_file}")"
        target_link="${AGENTS_DIR}${agent_name}"

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

        ln -s "${source_file}" "${target_link}"
        printf "  Installed: %s\n" "${agent_name}"
        installed_count=$((installed_count + 1))
    done < <(find "${AGENT_SOURCE}" -mindepth 2 -type f -name "*.md" -not -path "*/commands/*")

    printf "Installed %d repo agent(s), skipped %d existing agent(s)\n" "${installed_count}" "${skipped_count}"
    return 0
}

install_agents() {
    if ! validate_environment; then
        return 1
    fi

    if [ ! -d "${AGENTS_DIR}" ]; then
        printf "Creating agents directory: %s\n" "${AGENTS_DIR}"
        mkdir -p "${AGENTS_DIR}"
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

install_agents
