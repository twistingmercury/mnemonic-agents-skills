#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
TEMPLATE_ROOT="${SCRIPT_DIR}/../assets/full-project"
readonly TEMPLATE_ROOT

TARGET=""
API_NAME=""
RESOURCE_SINGULAR=""
RESOURCE_PLURAL=""
RESOURCE_ROUTE=""
PROJECT_SLUG=""
IMAGE_NAME=""
DATABASE_IMAGE_NAME=""
CI_BRANCH="main"
STAGING_DIR=""
INSTALL_IN_PROGRESS="false"
declare -a INSTALLED_ENTRIES=()

usage() {
    cat <<'USAGE'
Usage: scaffold.sh --api-name NAME \
  --resource-singular NAME --resource-plural NAME --resource-route ROUTE \
  [--project-slug SLUG] [--image-name IMAGE] \
  [--database-image-name IMAGE] [--ci-branch BRANCH]

Render the complete minimal API repository template into the empty current
working directory, which becomes the repository root.
USAGE
}

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

require_value() {
    local option="$1"
    local value="${2-}"

    if [ -z "${value}" ] || [[ "${value}" == --* ]]; then
        fail "${option} requires a value."
    fi
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --api-name|--resource-singular|--resource-plural|--resource-route|--project-slug|--image-name|--database-image-name|--ci-branch)
                require_value "$1" "${2-}"
                case "$1" in
                    --api-name) API_NAME="$2" ;;
                    --resource-singular) RESOURCE_SINGULAR="$2" ;;
                    --resource-plural) RESOURCE_PLURAL="$2" ;;
                    --resource-route) RESOURCE_ROUTE="$2" ;;
                    --project-slug) PROJECT_SLUG="$2" ;;
                    --image-name) IMAGE_NAME="$2" ;;
                    --database-image-name) DATABASE_IMAGE_NAME="$2" ;;
                    --ci-branch) CI_BRANCH="$2" ;;
                esac
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                fail "unknown option: $1"
                ;;
        esac
    done
}

validate_identifier() {
    local label="$1"
    local value="$2"

    if [[ ! "${value}" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
        fail "${label} must be an ASCII identifier beginning with a letter."
    fi
}

validate_api_name() {
    if [[ ! "${API_NAME}" =~ ^[A-Za-z][A-Za-z0-9]*(\.[A-Za-z][A-Za-z0-9]*)*$ ]]; then
        fail '--api-name must be a dot-separated C# identifier.'
    fi
}

validate_slug() {
    local label="$1"
    local value="$2"

    if [[ ! "${value}" =~ ^[a-z0-9]+([._-][a-z0-9]+)*$ ]]; then
        fail "${label} must contain lowercase letters, digits, and single separators (., _, or -)."
    fi
}

validate_image_name() {
    local label="$1"
    local value="$2"

    if [[ ! "${value}" =~ ^[a-z0-9]+([._:-][a-z0-9]+)*(\/[a-z0-9]+([._-][a-z0-9]+)*)+$ ]]; then
        fail "${label} must be a lowercase Docker image name without a tag or digest."
    fi
}

validate_ci_branch() {
    if [[ ! "${CI_BRANCH}" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*[A-Za-z0-9]$ ]] && [[ ! "${CI_BRANCH}" =~ ^[A-Za-z0-9]$ ]]; then
        fail '--ci-branch contains unsupported characters.'
    fi

    if [[ "${CI_BRANCH}" == *..* || "${CI_BRANCH}" == *//* || "${CI_BRANCH}" == */.* || "${CI_BRANCH}" == *.lock ]]; then
        fail '--ci-branch is not a safe Git branch name.'
    fi
}

validate_target() {
    TARGET="$(pwd -P)" || fail 'cannot resolve the current working directory.'

    [ -n "${TARGET}" ] || fail 'cannot resolve the current working directory.'
    [ "${TARGET}" != / ] || fail 'refusing to scaffold into the filesystem root.'
    [ -d "${TARGET}" ] || fail 'the current working directory must be an existing directory.'

    if [ -n "$(find "${TARGET}" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
        fail 'the current working directory must be empty.'
    fi
}

validate_configuration() {
    [ -n "${API_NAME}" ] || fail '--api-name is required.'
    [ -n "${RESOURCE_SINGULAR}" ] || fail '--resource-singular is required.'
    [ -n "${RESOURCE_PLURAL}" ] || fail '--resource-plural is required.'
    [ -n "${RESOURCE_ROUTE}" ] || fail '--resource-route is required.'
    [ -d "${TEMPLATE_ROOT}" ] || fail "template tree not found: ${TEMPLATE_ROOT}"

    validate_target
    validate_api_name
    validate_identifier '--resource-singular' "${RESOURCE_SINGULAR}"
    validate_identifier '--resource-plural' "${RESOURCE_PLURAL}"
    validate_slug '--resource-route' "${RESOURCE_ROUTE}"

    PROJECT_SLUG="${PROJECT_SLUG:-${RESOURCE_ROUTE}}"
    IMAGE_NAME="${IMAGE_NAME:-local/${PROJECT_SLUG}}"
    DATABASE_IMAGE_NAME="${DATABASE_IMAGE_NAME:-local/${PROJECT_SLUG}-postgres}"

    validate_slug '--project-slug' "${PROJECT_SLUG}"
    validate_image_name '--image-name' "${IMAGE_NAME}"
    validate_image_name '--database-image-name' "${DATABASE_IMAGE_NAME}"
    validate_ci_branch
}

replace_tokens() {
    local rendered="$1"

    rendered="${rendered//\{\{API_NAME\}\}/${API_NAME}}"
    rendered="${rendered//\{\{RESOURCE_SINGULAR\}\}/${RESOURCE_SINGULAR}}"
    rendered="${rendered//\{\{RESOURCE_PLURAL\}\}/${RESOURCE_PLURAL}}"
    rendered="${rendered//\{\{RESOURCE_ROUTE\}\}/${RESOURCE_ROUTE}}"
    rendered="${rendered//\{\{PROJECT_SLUG\}\}/${PROJECT_SLUG}}"
    rendered="${rendered//\{\{IMAGE_NAME\}\}/${IMAGE_NAME}}"
    rendered="${rendered//\{\{DATABASE_IMAGE_NAME\}\}/${DATABASE_IMAGE_NAME}}"
    rendered="${rendered//\{\{CI_BRANCH\}\}/${CI_BRANCH}}"
    printf '%s' "${rendered}"
}

render_path() {
    local rendered_path

    rendered_path="$(replace_tokens "$1")"
    printf '%s' "${rendered_path%.tmpl}"
}

render_file() {
    local source_file="$1"
    local relative_path="$2"
    local destination_file
    local content

    destination_file="${STAGING_DIR}/$(render_path "${relative_path}")"

    mkdir -p -- "$(dirname -- "${destination_file}")"
    content="$(<"${source_file}")"
    replace_tokens "${content}" > "${destination_file}"
    printf '\n' >> "${destination_file}"

    if [[ "${destination_file}" == *.sh ]]; then
        chmod 0755 "${destination_file}"
    fi
}

rollback_install() {
    local index
    local installed_path

    for ((index = ${#INSTALLED_ENTRIES[@]} - 1; index >= 0; index--)); do
        installed_path="${INSTALLED_ENTRIES[index]}"

        if [ ! -e "${installed_path}" ] && [ ! -L "${installed_path}" ]; then
            continue
        fi

        if ! mv -- "${installed_path}" "${STAGING_DIR}/"; then
            rm -rf -- "${installed_path}"
        fi
    done

    INSTALLED_ENTRIES=()
    INSTALL_IN_PROGRESS="false"
}

cleanup() {
    local exit_status=$?

    trap - EXIT

    if [ "${INSTALL_IN_PROGRESS}" = "true" ]; then
        rollback_install
    fi

    if [ -n "${STAGING_DIR}" ] && [ -d "${STAGING_DIR}" ]; then
        rm -rf -- "${STAGING_DIR}"
    fi

    exit "${exit_status}"
}

render_tree() {
    local source_path
    local relative_path
    local destination_path

    while IFS= read -r -d '' source_path; do
        relative_path="${source_path#"${TEMPLATE_ROOT}/"}"
        destination_path="${STAGING_DIR}/$(render_path "${relative_path}")"

        if [ -d "${source_path}" ]; then
            mkdir -p -- "${destination_path}"
            continue
        fi

        if [ -f "${source_path}" ]; then
            render_file "${source_path}" "${relative_path}"
            continue
        fi

        fail "unsupported template entry: ${source_path}"
    done < <(find "${TEMPLATE_ROOT}" -mindepth 1 -print0)
}

install_tree() {
    local staged_entry
    local entry_name
    local destination

    if [ -n "$(find "${TARGET}" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
        fail 'the current working directory stopped being empty during rendering.'
    fi

    INSTALL_IN_PROGRESS="true"

    while IFS= read -r -d '' staged_entry; do
        entry_name="$(basename -- "${staged_entry}")"
        destination="${TARGET}/${entry_name}"

        if [ -e "${destination}" ] || [ -L "${destination}" ]; then
            fail "destination entry appeared during installation: ${destination}"
        fi

        if ! mv -- "${staged_entry}" "${destination}"; then
            fail "could not install repository entry: ${entry_name}"
        fi

        INSTALLED_ENTRIES+=("${destination}")
    done < <(find "${STAGING_DIR}" -mindepth 1 -maxdepth 1 -print0)

    INSTALL_IN_PROGRESS="false"
    INSTALLED_ENTRIES=()
}

main() {
    local target_parent
    local target_name

    parse_args "$@"
    validate_configuration

    target_parent="$(dirname -- "${TARGET}")"
    target_name="$(basename -- "${TARGET}")"
    STAGING_DIR="$(mktemp -d "${target_parent}/.${target_name}.scaffold.XXXXXX")" || \
        fail "cannot create a staging directory beside ${TARGET}."
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    render_tree
    install_tree
    printf 'Created %s in the current repository root: %s\n' "${API_NAME}" "${TARGET}"
}

main "$@"
