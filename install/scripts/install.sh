#!/usr/bin/env bash

set -e

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
SETUP_DIR="${SETUP_DIR:-$(cd "${SCRIPTS}/.." && pwd)}"
PROJ_ROOT="${PROJ_ROOT:-$(cd "${SETUP_DIR}/.." && pwd)}"

# Set shared timestamp for all logs during this install run
export TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"

# shellcheck source=../lib/print.sh disable=SC1091
. "${SETUP_DIR}/lib/print.sh"

main(){
    print::info "Starting agent installation from ${PROJ_ROOT}"

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

    print::info "Step 3/3: Installing skills..."
    if ! "${SCRIPTS}/03-install-skills.sh"; then
        print::error "Failed to install skills"
        return 3
    fi

    print::success "Installation completed"
    return 0
}

main "$@"
