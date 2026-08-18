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
    print::info "Starting Codex installation from ${PROJ_ROOT}"

    print::info "Step 1/3: Installing agent definitions..."
    if ! "${SCRIPTS}/01-install-agents.sh"; then
        print::error "Failed to install agent definitions"
        return 1
    fi

    print::info "Step 2/3: Installing global agent rules..."
    if ! "${SCRIPTS}/02-install-global-agent-rules.sh"; then
        print::error "Failed to install global agent rules"
        return 2
    fi

    print::info "Step 3/3: Installing shared and Codex skills..."
    if ! "${SCRIPTS}/03-install-skills.sh"; then
        print::error "Failed to install skills"
        return 3
    fi

    print::success "Codex installation completed"
    return 0
}

main
