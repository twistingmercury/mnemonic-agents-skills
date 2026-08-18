#!/usr/bin/env bash

set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="${PROJ_ROOT:-$(cd "${SCRIPTS}/../.." && pwd)}"
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"

restore_backup_on_failure() {
    local exit_code="${1}"
    local backup="${GLOBAL_CONF}.${TIMESTAMP}.backup"
    if [ "${exit_code}" -ne 0 ] && [ -f "${backup}" ]; then
        print::warning "install failed — restoring backup: ${backup}"
        cp "${backup}" "${GLOBAL_CONF}" || print::error "restore failed: ${backup} -> ${GLOBAL_CONF}"
    fi
}

CLAUDE_ROOT="${CLAUDE_ROOT:-${HOME}/.claude}"
FORCE="${FORCE:-0}"
GLOBAL_CONF="${CLAUDE_ROOT}/CLAUDE.md"
AGENT_RULES_SOURCE="${AGENT_RULES_SOURCE:-${PROJ_ROOT}/claude/agents/GLOBAL_AGENT_RULES.md}"

# shellcheck source=../../lib/print.sh disable=SC1091
. "${PROJ_ROOT}/lib/print.sh"

## Not every Claude Code install may have a global Claude.md file.
## So when that situation is encountered, we'll need to create it for the user.
create_global_claude_config(){
    print::info "no global CLAUDE.md file exists - creating"

    printf "# CLAUDE.md\n" > "${GLOBAL_CONF}" || {
        print::error "failed to write to new global config: ${GLOBAL_CONF}"
        return 1
    }

    print::success "global CLAUDE.md file created: ${GLOBAL_CONF}"
    _config_just_created=1

    return 0
}

## If the user has global Claude.md, we need to back it up in case
## something goes wrong, so it can be restored, even if manually.
backup_global_claude_config(){
    local backup="${GLOBAL_CONF}.${TIMESTAMP}.backup"

    cp "${GLOBAL_CONF}" "${backup}" || {
        print::error "failed to backup the global config: ${GLOBAL_CONF}"
        return 1
    }

    return 0
}

## Extract the date from agent rules content
## Returns the date string in YYYY-MM-DD format or empty if not found
extract_rules_date() {
    local file="${1}"

    if [ ! -f "${file}" ]; then
        return 0
    fi

    # Extract YYYY-MM-DD from "**Last Updated: YYYY-MM-DD**" line
    sed -n -E 's/^\*\*Last Updated: ([0-9]{4}-[0-9]{2}-[0-9]{2})\*\*$/\1/p' "${file}" | head -n 1

    return 0
}

## Check if agent rules section exists in the file
has_agent_rules() {
    local file="${1}"

    if [ ! -f "${file}" ]; then
        return 1
    fi

    if grep -q "<!-- BEGIN AGENT RULES -->" "${file}"; then
        return 0
    else
        return 1
    fi
}

## Remove existing agent rules section from CLAUDE.md
## Uses markers: <!-- BEGIN AGENT RULES --> to <!-- END AGENT RULES -->
remove_existing_agent_rules() {
    local claude_file="${1}"

    if [ ! -f "${claude_file}" ]; then
        print::error "file does not exist: ${claude_file}"
        return 1
    fi

    # Create temporary file
    local temp_file
    temp_file="$(mktemp)" || {
        print::error "failed to create temporary file"
        return 1
    }

    # Remove content between markers (inclusive)
    # This uses sed to delete from BEGIN to END markers
    sed '/<!-- BEGIN AGENT RULES -->/,/<!-- END AGENT RULES -->/d' "${claude_file}" > "${temp_file}" || {
        rm -f "${temp_file}"
        print::error "failed to remove agent rules section"
        return 1
    }

    # Replace original file with modified content
    mv "${temp_file}" "${claude_file}" || {
        rm -f "${temp_file}"
        print::error "failed to update ${claude_file}"
        return 1
    }

    return 0
}

## Compare dates in YYYY-MM-DD format
## Returns 0 if date1 >= date2, 1 otherwise
compare_dates() {
    local date1="${1}"
    local date2="${2}"

    # Validate both dates are in YYYY-MM-DD format (only format supported)
    case "${date1}" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
        *) printf "ERROR: invalid date format: %s (expected YYYY-MM-DD)\n" "${date1}" >&2; return 1 ;;
    esac
    case "${date2}" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
        *) printf "ERROR: invalid date format: %s (expected YYYY-MM-DD)\n" "${date2}" >&2; return 1 ;;
    esac

    # Remove hyphens and compare as integers
    local num1="${date1//-/}"
    local num2="${date2//-/}"

    [ "${num1}" -ge "${num2}" ]
}

install_global_agent_rules() {
    local _config_just_created=0

    # Validation
    if [ ! -f "${AGENT_RULES_SOURCE}" ]; then
        print::error "could not locate agent rules source file: ${AGENT_RULES_SOURCE}"
        return 1
    fi

    if [ ! -d "${CLAUDE_ROOT}" ]; then
        print::error "could not locate expected config for Claude Code: ${CLAUDE_ROOT}"
        return 1
    fi

    # Create global CLAUDE.md if it doesn't exist
    if [ ! -f "${GLOBAL_CONF}" ]; then
        create_global_claude_config || return 1
    fi

    # Extract source date from agent rules
    local source_date
    source_date=$(extract_rules_date "${AGENT_RULES_SOURCE}")

    if [ -z "${source_date}" ]; then
        print::error "could not extract date from agent rules source: ${AGENT_RULES_SOURCE}"
        return 1
    fi

    # Check if agent rules already exist in CLAUDE.md
    if has_agent_rules "${GLOBAL_CONF}"; then
        local installed_date
        installed_date=$(extract_rules_date "${GLOBAL_CONF}")

        if [ -z "${installed_date}" ]; then
            print::warning "found agent rules but could not extract date, will reinstall"
        elif compare_dates "${installed_date}" "${source_date}" && [ "${FORCE}" -ne 1 ]; then
            print::info "agent rules are up to date (${installed_date})"
            return 0
        else
            print::info "updating agent rules (old: ${installed_date}, new: ${source_date})"
            backup_global_claude_config || return 1
            trap 'restore_backup_on_failure $?' RETURN
            remove_existing_agent_rules "${GLOBAL_CONF}" || return 1
        fi
    else
        print::info "installing agent rules for the first time (${source_date})"
        if [ "${_config_just_created}" -eq 0 ]; then
            backup_global_claude_config || return 1
            trap 'restore_backup_on_failure $?' RETURN
        fi
    fi

    # Append agent rules to CLAUDE.md
    cat "${AGENT_RULES_SOURCE}" >> "${GLOBAL_CONF}" || {
        print::error "failed to append agent rules to global config: ${GLOBAL_CONF}"
        return 1
    }

    print::success "agent rules written to global CLAUDE.md (${source_date})"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_global_agent_rules
fi
