#!/usr/bin/env bash

set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="${PROJ_ROOT:-$(cd "${SCRIPTS}/../.." && pwd)}"

# shellcheck source=../../lib/print.sh disable=SC1091
. "${PROJ_ROOT}/lib/print.sh"

CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
CODEX_HOME="${CODEX_HOME%/}"
GLOBAL_AGENTS_SOURCE="${GLOBAL_AGENTS_SOURCE:-${PROJ_ROOT}/codex/agents/global-agents.md}"
GLOBAL_AGENTS_TARGET="${CODEX_HOME}/AGENTS.md"

main() {
	if [ ! -f "${GLOBAL_AGENTS_SOURCE}" ] || [ ! -s "${GLOBAL_AGENTS_SOURCE}" ]; then
		print::error "global agent rules source must be a nonempty regular file: ${GLOBAL_AGENTS_SOURCE}"
		return 1
	fi

	if [ ! -d "${CODEX_HOME}" ]; then
		print::info "creating dir ${CODEX_HOME}..."
		mkdir -p "${CODEX_HOME}"
	fi

	local override_file="${CODEX_HOME}/AGENTS.override.md"
	if [ -s "${override_file}" ]; then
		print::warning "nonempty AGENTS.override.md takes precedence; installed global rules will be inactive: ${override_file}"
	fi

	install -m 0644 "${GLOBAL_AGENTS_SOURCE}" "${GLOBAL_AGENTS_TARGET}"

	print::success "global agent rules installed: ${GLOBAL_AGENTS_TARGET}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main
fi
