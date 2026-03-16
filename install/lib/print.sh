#!/usr/bin/env bash

# Print info message
print::info() {
    printf "[INFO] %s\n" "$*"
}

# Print success message
print::success() {
    printf "[SUCCESS] %s\n" "$*"
}

# Print error message to stderr
print::error() {
    printf "[ERROR] %s\n" "$*" >&2
}

# Print warning message to stderr
print::warning() {
    printf "[WARNING] %s\n" "$*" >&2
}
