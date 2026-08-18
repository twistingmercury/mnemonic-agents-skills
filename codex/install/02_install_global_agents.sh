#!/usr/bin/env bash

set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="${PROJ_ROOT:-$(cd "${SCRIPTS}/../.." && pwd)}"

GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE:-${PROJ_ROOT}/codex/agents/global-agents.md}"
CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
GLOBAL_AGENTS_TARGET="${CODEX_HOME}/AGENTS.md"
FORCE="${FORCE:-0}"

# shellcheck source=../../lib/print.sh disable=SC1091
. "${PROJ_ROOT}/lib/print.sh"

is_unsafe_codex_home() {
    local resolved_home

    if [ -z "${CODEX_HOME}" ] || [ -z "${CODEX_HOME//\//}" ]; then
        return 0
    fi

    # Parent traversal is unnecessary for CODEX_HOME and can become root after
    # mkdir creates a previously missing component (for example /new/..).
    case "/${CODEX_HOME}/" in
        */../*)
            return 0
            ;;
    esac

    if [ -d "${CODEX_HOME}" ]; then
        if ! resolved_home="$(cd "${CODEX_HOME}" && pwd -P)"; then
            return 0
        fi

        if [ "${resolved_home}" = "/" ]; then
            return 0
        fi
    fi

    return 1
}

validate_environment() {
    if [ ! -f "${GLOBAL_AGENTS_SOURCE}" ] || [ ! -s "${GLOBAL_AGENTS_SOURCE}" ]; then
        print::error "global agent rules source must be a nonempty regular file: ${GLOBAL_AGENTS_SOURCE}"
        return 1
    fi

    if is_unsafe_codex_home; then
        print::error "CODEX_HOME is unsafe: '${CODEX_HOME}'"
        return 1
    fi

    return 0
}

absolute_source_path() {
    local source_dir
    local source_name

    source_dir="$(dirname "${GLOBAL_AGENTS_SOURCE}")"
    source_name="$(basename "${GLOBAL_AGENTS_SOURCE}")"

    if ! source_dir="$(cd "${source_dir}" && pwd -P)"; then
        print::error "failed to resolve global agent rules source: ${GLOBAL_AGENTS_SOURCE}"
        return 1
    fi

    printf '%s/%s\n' "${source_dir}" "${source_name}"
}

is_repo_managed_link() {
    local link_target="${1}"
    local expected_source="${2}"

    if [ "${link_target}" = "${expected_source}" ]; then
        return 0
    fi

    case "${link_target}" in
        */codex/agents/global-agents.md | \
        */agents/codex/global-agents.md)
            return 0
            ;;
    esac

    return 1
}

warn_about_override() {
    local override_file="${CODEX_HOME}/AGENTS.override.md"

    if [ -f "${override_file}" ] && [ -s "${override_file}" ]; then
        print::warning "nonempty AGENTS.override.md takes precedence; installed global rules will be inactive: ${override_file}"
    fi
}

replace_link() {
    local expected_source="${1}"

    if ! rm "${GLOBAL_AGENTS_TARGET}"; then
        print::error "failed to remove existing global agent rules link: ${GLOBAL_AGENTS_TARGET}"
        return 1
    fi

    if ! ln -s "${expected_source}" "${GLOBAL_AGENTS_TARGET}"; then
        print::error "failed to install global agent rules link: ${GLOBAL_AGENTS_TARGET}"
        return 1
    fi

    print::success "Installed global agent rules: ${GLOBAL_AGENTS_TARGET} -> ${expected_source}"
    return 0
}

install_global_agent_rules() {
    local expected_source
    local link_target

    if ! validate_environment; then
        return 1
    fi

    if ! expected_source="$(absolute_source_path)"; then
        return 1
    fi

    if [ ! -d "${CODEX_HOME}" ]; then
        print::info "Creating Codex home directory: ${CODEX_HOME}"
        if ! mkdir -p "${CODEX_HOME}"; then
            print::error "failed to create Codex home directory: ${CODEX_HOME}"
            return 1
        fi
    fi

    warn_about_override

    if [ -L "${GLOBAL_AGENTS_TARGET}" ]; then
        if ! link_target="$(readlink "${GLOBAL_AGENTS_TARGET}")"; then
            print::error "failed to read existing global agent rules link: ${GLOBAL_AGENTS_TARGET}"
            return 1
        fi

        if [ "${link_target}" = "${expected_source}" ]; then
            print::info "Global agent rules already installed: ${GLOBAL_AGENTS_TARGET}"
            return 0
        fi

        # FORCE refreshes symlinks only. Regular files and directories remain
        # user-owned even when FORCE=1, matching the conservative agent installer.
        if is_repo_managed_link "${link_target}" "${expected_source}" || [ "${FORCE}" = "1" ]; then
            if ! replace_link "${expected_source}"; then
                return 1
            fi
            return 0
        fi

        print::warning "Preserving unrelated symlink: ${GLOBAL_AGENTS_TARGET} -> ${link_target}"
        return 0
    fi

    if [ -e "${GLOBAL_AGENTS_TARGET}" ]; then
        print::warning "Preserving existing non-symlink path: ${GLOBAL_AGENTS_TARGET}"
        return 0
    fi

    if ! ln -s "${expected_source}" "${GLOBAL_AGENTS_TARGET}"; then
        print::error "failed to install global agent rules link: ${GLOBAL_AGENTS_TARGET}"
        return 1
    fi

    print::success "Installed global agent rules: ${GLOBAL_AGENTS_TARGET} -> ${expected_source}"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_global_agent_rules
fi
