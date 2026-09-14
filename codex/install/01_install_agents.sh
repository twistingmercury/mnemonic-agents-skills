#!/usr/bin/env bash

set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="${PROJ_ROOT:-$(cd "${SCRIPTS}/../.." && pwd)}"

CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
AGENT_SOURCE="${AGENT_SOURCE:-${PROJ_ROOT}/codex/agents}"
AGENTS_DIR="${AGENTS_DIR:-${CODEX_HOME}/agents}"

main() {
	if [ ! -d "$AGENTS_DIR" ]; then
		printf "creating dir %s...\n" "$AGENTS_DIR"
		mkdir -p "$AGENTS_DIR"
	fi

	local -a agentDirs
	mapfile -t agentDirs < <(find "$AGENT_SOURCE" -mindepth 1 -maxdepth 1 -type d)

	if ((${#agentDirs[@]} == 0)); then
		printf "Error: no agents were found in the directory %s\n" "$AGENT_SOURCE"
		return 1
	fi

	shopt -s nullglob
	for dir in "${agentDirs[@]}"; do
		local -a files=("${dir}"/*.toml)
		[ "${#files[@]}" -eq 0 ] && continue
		install -m 0644 "${files[@]}" "${AGENTS_DIR}/"
	done
}

main "$@"
