#!/usr/bin/env bash

set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="${PROJ_ROOT:-$(cd "${SCRIPTS}/../.." && pwd)}"

SKILL_SOURCE="${SKILL_SOURCE:-}"
SHARED_SKILL_SOURCE="${SHARED_SKILL_SOURCE:-${PROJ_ROOT}/shared/skills}"
PLATFORM_SKILL_SOURCE="${PLATFORM_SKILL_SOURCE:-${PROJ_ROOT}/codex/skills}"
CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
SKILLS_DIR="${SKILLS_DIR:-${CODEX_HOME}/skills/}"

# shellcheck source=lib/managed_state.sh disable=SC1091
. "${SCRIPTS}/lib/managed_state.sh"

skill_source_dirs() {
    if [ -n "${SKILL_SOURCE}" ]; then
        printf '%s\n' "${SKILL_SOURCE}"
        return 0
    fi

    # Platform-specific definitions take precedence when the optional directory exists.
    if [ -d "${PLATFORM_SKILL_SOURCE}" ]; then
        printf '%s\n' "${PLATFORM_SKILL_SOURCE}"
    fi
    printf '%s\n' "${SHARED_SKILL_SOURCE}"
}

is_unsafe_skills_dir() {
    local resolved_dir

    if [ -z "${SKILLS_DIR}" ] || [ -z "${SKILLS_DIR//\//}" ]; then
        return 0
    fi

    if [ -d "${SKILLS_DIR}" ]; then
        if ! resolved_dir="$(cd "${SKILLS_DIR}" && pwd -P)"; then
            return 0
        fi
        [ "${resolved_dir}" = "/" ] && return 0
    fi

    return 1
}

validate_environment() {
    local source_dir

    while IFS= read -r source_dir; do
        if [ ! -d "${source_dir}" ]; then
            printf "ERROR: cannot locate the project's skill directory: %s\n" "${source_dir}" >&2
            return 1
        fi
    done < <(skill_source_dirs)

    if is_unsafe_skills_dir; then
        printf "ERROR: SKILLS_DIR is unsafe: '%s'\n" "${SKILLS_DIR}" >&2
        return 1
    fi

    if ! command -v rsync >/dev/null 2>&1; then
        printf "ERROR: rsync is required to materialize Codex skills; install rsync and retry.\n" >&2
        return 1
    fi

    return 0
}

# Build a list of skill directory names from all applicable sources.
# A skill is any subdirectory of skills/ that contains a SKILL.md file.
list_repo_skills() {
    local source_dir

    while IFS= read -r source_dir; do
        find "${source_dir}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
    done < <(skill_source_dirs) | sort -u
}

find_skill_source() {
    local skill_name="${1}"
    local source_dir

    while IFS= read -r source_dir; do
        if [ -d "${source_dir}/${skill_name}" ]; then
            printf '%s\n' "${source_dir}/${skill_name}"
            return 0
        fi
    done < <(skill_source_dirs)

    return 1
}

is_recognized_legacy_skill_link() {
    local link_target="${1}"
    local skill_name="${2}"
    local expected_source="${3}"

    if [ "${link_target}" = "${expected_source}" ]; then
        return 0
    fi

    case "${link_target}" in
        */shared/skills/"${skill_name}" | */codex/skills/"${skill_name}" | */skills/codex/"${skill_name}")
            return 0
            ;;
    esac
    return 1
}

materialize_skill() {
    local source_dir="${1}"
    local target_dir="${2}"
    local temporary_dir

    if ! temporary_dir="$(mktemp -d "${target_dir}.tmp.XXXXXX")"; then
        printf "ERROR: failed to create temporary skill directory: %s\n" "${target_dir}" >&2
        return 1
    fi
    if ! rsync -a --delete "${source_dir}/" "${temporary_dir}/"; then
        rm -rf "${temporary_dir}"
        printf "ERROR: failed to materialize skill: %s\n" "$(basename "${source_dir}")" >&2
        return 1
    fi

    # This function is called only for a new path, a recognized repository link,
    # or a manifest-owned directory. Never remove an untracked user path.
    if [ -e "${target_dir}" ] || [ -L "${target_dir}" ]; then
        if ! rm -rf "${target_dir}"; then
            rm -rf "${temporary_dir}"
            printf "ERROR: failed to replace managed skill: %s\n" "$(basename "${source_dir}")" >&2
            return 1
        fi
    fi
    if ! mv "${temporary_dir}" "${target_dir}"; then
        rm -rf "${temporary_dir}"
        printf "ERROR: failed to install skill: %s\n" "$(basename "${source_dir}")" >&2
        return 1
    fi
}

install_repo_skills() {
    local installed_count=0
    local skipped_count=0
    local skill_name

    if is_unsafe_skills_dir; then
        printf "ERROR: SKILLS_DIR is unsafe: '%s'\n" "${SKILLS_DIR}" >&2
        return 1
    fi

    printf "Installing repo skills...\n"

    while IFS= read -r skill_name; do
        local source_dir
        local target_dir
        local managed_path
        local link_target
        source_dir="$(find_skill_source "${skill_name}")"
        target_dir="${SKILLS_DIR%/}/${skill_name}"
        managed_path="skills/${skill_name}"

        if [ -L "${target_dir}" ]; then
            if ! link_target="$(readlink "${target_dir}")"; then
                printf "ERROR: failed to read skill link: %s\n" "${target_dir}" >&2
                return 1
            fi
            if ! is_recognized_legacy_skill_link "${link_target}" "${skill_name}" "${source_dir}"; then
                printf "  Preserving unrelated symlink: %s\n" "${skill_name}"
                skipped_count=$((skipped_count + 1))
                continue
            fi
        elif [ -e "${target_dir}" ] && ! managed_state_is_managed "${managed_path}"; then
            printf "  Skipping existing non-symlink path: %s\n" "${skill_name}"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        if ! materialize_skill "${source_dir}" "${target_dir}"; then
            return 1
        fi
        if ! managed_state_mark "${managed_path}"; then
            return 1
        fi
        printf "  Installed: %s\n" "${skill_name}"
        installed_count=$((installed_count + 1))
    done < <(list_repo_skills)

    printf "Installed %d repo skill(s), skipped %d existing skill(s)\n" "${installed_count}" "${skipped_count}"
    return 0
}

install_skills() {
    if ! validate_environment; then
        return 1
    fi

    if [ ! -d "${SKILLS_DIR}" ]; then
        printf "Creating skills directory: %s\n" "${SKILLS_DIR}"
        if ! mkdir -p "${SKILLS_DIR}"; then
            printf "ERROR: failed to create skills directory: %s\n" "${SKILLS_DIR}" >&2
            return 1
        fi
    fi

    if ! install_repo_skills; then
        printf "ERROR: failed to install repo skills\n" >&2
        return 1
    fi

    printf "\nSUCCESS: all skills updated\n"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_skills
fi
