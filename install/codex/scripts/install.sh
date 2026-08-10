#!/usr/bin/env bash

set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MNEMONIC_INSTALL_ROOT="${MNEMONIC_INSTALL_ROOT:-$(cd "${SCRIPTS}/../.." && pwd)}"
PROJ_ROOT="${PROJ_ROOT:-$(cd "${MNEMONIC_INSTALL_ROOT}/.." && pwd)}"

# Set shared timestamp for all logs during this install run
export TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"

# shellcheck source=../lib/print.sh disable=SC1091
. "${MNEMONIC_INSTALL_ROOT}/lib/print.sh"

main(){
    print::info "Starting Codex skill installation from ${PROJ_ROOT}"

    print::info "Installing shared and Codex skills..."
    if ! "${SCRIPTS}/03-install-skills.sh"; then
        print::error "Failed to install skills"
        return 1
    fi

    print::success "Codex skill installation completed"
    return 0
}

main
