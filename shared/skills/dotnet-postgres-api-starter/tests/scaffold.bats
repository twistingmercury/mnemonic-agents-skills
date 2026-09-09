#!/usr/bin/env bats

setup() {
    SCRIPT="${BATS_TEST_DIRNAME}/../scripts/scaffold.sh"
    TEST_ROOT="${BATS_TEST_TMPDIR}/case"
    TARGET="${TEST_ROOT}/generated-api"
    mkdir -p "${TARGET}"
}

teardown() {
    rm -rf -- "${TEST_ROOT}"
}

run_scaffold() {
    run bash -c 'cd -- "$1" && shift && exec "$@"' _ "${TARGET}" "${SCRIPT}" \
        --api-name "${1:-Catalog.Api}" \
        --resource-singular "${2:-Product}" \
        --resource-plural "${3:-Products}" \
        --resource-route "${4:-products}" \
        "${@:5}"
}

assert_empty_repository_root() {
    run find "${TARGET}" -mindepth 1 -maxdepth 1 -print -quit
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

assert_no_staging_directory() {
    run find "${TEST_ROOT}" -mindepth 1 -maxdepth 1 \
        -name '.generated-api.scaffold.*' -print -quit
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

directory_inode() {
    if stat -c '%i' "$1" 2>/dev/null; then
        return
    fi

    stat -f '%i' "$1"
}

prepare_ci_build_step() {
    run_scaffold
    [ "${status}" -eq 0 ]

    awk '
        /^      - name: Build and test the image$/ { step = 1; next }
        step && /^      - / { exit }
        step && /^        run: \|$/ { block = 1; next }
        block && /^          / { sub(/^          /, ""); print }
    ' "${TARGET}/.github/workflows/ci.yaml" > "${TEST_ROOT}/ci-build.sh"
    [ -s "${TEST_ROOT}/ci-build.sh" ]

    cat > "${TARGET}/build/build.sh" <<'SHIM'
#!/usr/bin/env bash
set -eu
printf '%s\n' "${IMAGE_NAME}" "${LOCAL}" > "${CI_TEST_BUILD_RECORD}"
SHIM
    chmod +x "${TARGET}/build/build.sh"
}

run_ci_build_step() {
    # Positional parameters are expanded by the subprocess after changing directory.
    # shellcheck disable=SC2016
    run env IMAGE_NAME="$1" GITHUB_REPOSITORY='Acme/Products' \
        CI_TEST_BUILD_RECORD="${TEST_ROOT}/build-record" \
        bash -c 'cd -- "$1" && exec bash --noprofile --norc -eo pipefail "$2"' _ \
        "${TARGET}" "${TEST_ROOT}/ci-build.sh"
}

@test "CI defaults to a lowercase GHCR repository and invokes the CI builder" {
    prepare_ci_build_step

    run_ci_build_step ''

    [ "${status}" -eq 0 ]
    printf 'ghcr.io/acme/products\n0\n' > "${TEST_ROOT}/expected-build-record"
    cmp "${TEST_ROOT}/expected-build-record" "${TEST_ROOT}/build-record"
}

@test "CI honors an explicit GHCR repository override" {
    prepare_ci_build_step

    run_ci_build_step 'ghcr.io/another-owner/service-images/products_api'

    [ "${status}" -eq 0 ]
    printf 'ghcr.io/another-owner/service-images/products_api\n0\n' > "${TEST_ROOT}/expected-build-record"
    cmp "${TEST_ROOT}/expected-build-record" "${TEST_ROOT}/build-record"
}

@test "CI rejects non-GHCR tagged digest and uppercase image names before building" {
    prepare_ci_build_step
    local image_name

    for image_name in \
        'local/products' \
        'registry.example/acme/products' \
        'ghcr.io/acme/products:latest' \
        'ghcr.io/acme/products@sha256:0123456789abcdef' \
        'ghcr.io/Acme/Products'; do
        run_ci_build_step "${image_name}"

        [ "${status}" -ne 0 ]
        [[ "${output}" == *'IMAGE_NAME must be a lowercase ghcr.io/<owner>/<image> repository without a tag or digest'* ]]
        [ ! -e "${TEST_ROOT}/build-record" ]
    done
}

@test "renders the complete repository with custom values into the current directory" {
    run_scaffold "Acme.Inventory.Api" "InventoryItem" "InventoryItems" "inventory-items" \
        --project-slug "warehouse-api" \
        --image-name "registry.example/acme/warehouse-api" \
        --database-image-name "registry.example/acme/warehouse-postgres" \
        --ci-branch "release/v2"

    [ "${status}" -eq 0 ]
    [ "${output}" = "Created Acme.Inventory.Api in the current repository root: ${TARGET}" ]

    for path in \
        .dockerignore \
        .github/workflows/ci.yaml \
        .gitignore \
        Makefile \
        README.md \
        build/Dockerfile \
        build/build.sh \
        build/test-black-box.sh \
        build/tests/build_scripts.bats \
        database/Dockerfile \
        database/build.sh \
        database/docker-migrate.sh \
        database/lib/helpers.sh \
        database/migrate.sh \
        database/tests/database_scripts.bats \
        database/sql/create_database.sql \
        database/sql/create_tables.sql \
        database/sql/create_user.sql \
        database/sql/seed_inventory-items.sql \
        deploy/envoy/Chart.yaml \
        deploy/envoy/envoy.yaml \
        deploy/warehouse-api/Chart.yaml \
        deploy/warehouse-api/templates/deployment.yaml \
        deploy/warehouse-api/templates/networkpolicy.yaml \
        deploy/warehouse-api/values.yaml \
        docker-compose.yaml \
        scripts/analyze.sh \
        src/Acme.Inventory.ApiSolution.slnx \
        src/Acme.Inventory.Api/Acme.Inventory.Api.csproj \
        src/Acme.Inventory.Api/Program.cs \
        src/Acme.Inventory.Api/DataAccess/InventoryItemDbContext.cs \
        src/Acme.Inventory.Api/DataAccess/DTOs/InventoryItemDto.cs \
        src/Acme.Inventory.Api/Endpoints/InventoryItemEndpoints.cs \
        src/Acme.Inventory.Api/Handlers/InventoryItemHandlers.cs \
        src/Acme.Inventory.Api/Models/InventoryItem.cs \
        src/Tests/Unit/Acme.Inventory.Api.Tests.Unit.csproj \
        src/Tests/Unit/InventoryItemModelTests.cs \
        src/Tests/BlackBox/Acme.Inventory.Api.Tests.BlackBox.csproj \
        src/Tests/BlackBox/InventoryItemApiTests.cs; do
        [ -f "${TARGET}/${path}" ]
    done

    grep -Fq 'namespace Acme.Inventory.Api;' "${TARGET}/src/Acme.Inventory.Api/Program.cs"
    grep -Fq 'MapInventoryItems' "${TARGET}/src/Acme.Inventory.Api/Program.cs"
    grep -Fq 'MapGroup("/inventory-items")' "${TARGET}/src/Acme.Inventory.Api/Endpoints/InventoryItemEndpoints.cs"
    grep -Fq 'registry.example/acme/warehouse-api:local' "${TARGET}/docker-compose.yaml"
    grep -Fq 'registry.example/acme/warehouse-postgres:local' "${TARGET}/docker-compose.yaml"
    grep -Fq 'release/v2' "${TARGET}/.github/workflows/ci.yaml"

    run find "${TARGET}" -name '*.tmpl' -print -quit
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]

    run grep -R -E '\{\{(API_NAME|RESOURCE_SINGULAR|RESOURCE_PLURAL|RESOURCE_ROUTE|PROJECT_SLUG|IMAGE_NAME|DATABASE_IMAGE_NAME|CI_BRANCH)\}\}' "${TARGET}"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]

    while IFS= read -r shell_file; do
        [ -x "${shell_file}" ]
    done < <(find "${TARGET}" -type f -name '*.sh' -print)
}

@test "uses route-derived project and image defaults and the main branch" {
    run_scaffold "Catalog.Api" "Product" "Products" "store-items"

    [ "${status}" -eq 0 ]
    [ -d "${TARGET}/deploy/store-items" ]
    grep -Fq 'image: local/store-items:local' "${TARGET}/docker-compose.yaml"
    grep -Fq 'image: local/store-items-postgres:local' "${TARGET}/docker-compose.yaml"
    grep -Fq 'main' "${TARGET}/.github/workflows/ci.yaml"
}

@test "rejects each missing required argument without partial output" {
    local required_option

    for required_option in api-name resource-singular resource-plural resource-route; do
        local -a arguments=(
            --api-name Catalog.Api
            --resource-singular Product
            --resource-plural Products
            --resource-route products
        )
        local -a filtered=()
        local index=0

        while [ "${index}" -lt "${#arguments[@]}" ]; do
            if [ "${arguments[${index}]}" = "--${required_option}" ]; then
                index=$((index + 2))
                continue
            fi
            filtered+=("${arguments[${index}]}" "${arguments[$((index + 1))]}")
            index=$((index + 2))
        done

        run bash -c 'cd -- "$1" && shift && exec "$@"' _ \
            "${TARGET}" "${SCRIPT}" "${filtered[@]}"
        [ "${status}" -ne 0 ]
        [[ "${output}" == *"--${required_option} is required."* ]]
        assert_empty_repository_root
        assert_no_staging_directory
    done
}

@test "rejects invalid identifiers, slugs, image names, and branches atomically" {
    local field
    local value
    local expected

    while IFS='|' read -r field value expected; do
        local -a optional=()
        local api_name="Catalog.Api"
        local singular="Product"
        local plural="Products"
        local route="products"

        case "${field}" in
            api-name) api_name="${value}" ;;
            resource-singular) singular="${value}" ;;
            resource-plural) plural="${value}" ;;
            resource-route) route="${value}" ;;
            *) optional=("--${field}" "${value}") ;;
        esac

        run_scaffold "${api_name}" "${singular}" "${plural}" "${route}" "${optional[@]}"
        [ "${status}" -ne 0 ]
        [[ "${output}" == *"${expected}"* ]]
        assert_empty_repository_root
        assert_no_staging_directory
    done <<'CASES'
api-name|Catalog-Api|--api-name must be a dot-separated C# identifier.
resource-singular|9Product|--resource-singular must be an ASCII identifier beginning with a letter.
resource-plural|Product Items|--resource-plural must be an ASCII identifier beginning with a letter.
resource-route|Product_Items|--resource-route must contain lowercase letters, digits, and single separators
project-slug|Warehouse API|--project-slug must contain lowercase letters, digits, and single separators
image-name|Warehouse/API|--image-name must be a lowercase Docker image name without a tag or digest.
database-image-name|postgres|--database-image-name must be a lowercase Docker image name without a tag or digest.
ci-branch|release..v2|--ci-branch is not a safe Git branch name.
CASES
}

@test "rejects --target as an unknown option without partial output" {
    run bash -c 'cd -- "$1" && shift && exec "$@"' _ "${TARGET}" "${SCRIPT}" \
        --target "${TEST_ROOT}/other"

    [ "${status}" -ne 0 ]
    [[ "${output}" == *'unknown option: --target'* ]]
    assert_empty_repository_root
    assert_no_staging_directory
}

@test "rejects a nonempty current directory without changing its contents" {
    printf 'keep me\n' > "${TARGET}/sentinel"

    run_scaffold

    [ "${status}" -ne 0 ]
    [[ "${output}" == *'blocking entry in the current working directory: sentinel;'* ]]
    [ "$(cat "${TARGET}/sentinel")" = 'keep me' ]
    [ "$(find "${TARGET}" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]
    assert_no_staging_directory
}

@test "help explains the repository root and permitted workspace metadata" {
    run bash -c 'cd -- "$1" && shift && exec "$@"' _ "${TARGET}" "${SCRIPT}" --help

    [ "${status}" -eq 0 ]
    [[ "${output}" == *'current working'* ]]
    [[ "${output}" == *'empty except for real'* ]]
    [[ "${output}" == *'.git, .codex, .claude, or .agents directories'* ]]
    [[ "${output}" == *'regular .git worktree file'* ]]
    [[ "${output}" == *'symbolic links are not allowed'* ]]
    [[ "${output}" == *'becomes the repository root'* ]]
    assert_empty_repository_root
    assert_no_staging_directory
}

@test "successful rendering preserves the current directory itself" {
    local inode_before
    local inode_after

    inode_before="$(directory_inode "${TARGET}")"
    run_scaffold
    inode_after="$(directory_inode "${TARGET}")"

    [ "${status}" -eq 0 ]
    [ "${inode_after}" = "${inode_before}" ]
    [ -f "${TARGET}/src/Catalog.Api/Program.cs" ]
    assert_no_staging_directory
}

@test "an option missing its value leaves the current directory empty and no staging directory" {
    run bash -c 'cd -- "$1" && shift && exec "$@"' _ "${TARGET}" "${SCRIPT}" \
        --api-name Catalog.Api \
        --resource-singular Product \
        --resource-plural Products \
        --resource-route

    [ "${status}" -ne 0 ]
    [[ "${output}" == *'--resource-route requires a value.'* ]]
    assert_empty_repository_root
    assert_no_staging_directory
}

@test "scaffolds alongside workspace metadata and preserves nested contents" {
    local metadata
    for metadata in .git .codex .claude .agents; do
        mkdir -p "${TARGET}/${metadata}/nested"
        printf '%s\n' "preserve ${metadata}" > "${TARGET}/${metadata}/nested/config"
    done

    run_scaffold

    [ "${status}" -eq 0 ]
    [ -f "${TARGET}/src/Catalog.Api/Program.cs" ]
    for metadata in .git .codex .claude .agents; do
        [ "$(cat "${TARGET}/${metadata}/nested/config")" = "preserve ${metadata}" ]
        [ "$(find "${TARGET}/${metadata}" -type f | wc -l)" -eq 1 ]
    done
    assert_no_staging_directory
}

@test "scaffolds alongside a regular git worktree file without changing it" {
    printf 'gitdir: /example/worktrees/catalog\n' > "${TARGET}/.git"
    cp "${TARGET}/.git" "${TEST_ROOT}/expected-git"

    run_scaffold

    [ "${status}" -eq 0 ]
    [ -f "${TARGET}/src/Catalog.Api/Program.cs" ]
    cmp "${TEST_ROOT}/expected-git" "${TARGET}/.git"
    assert_no_staging_directory
}

@test "rejects live and dangling metadata symlinks without changing their targets" {
    local metadata
    local link_target
    mkdir -p "${TEST_ROOT}/existing"
    printf 'external content\n' > "${TEST_ROOT}/existing/sentinel"

    for metadata in .git .codex .claude .agents; do
        for link_target in existing missing; do
            ln -s "${TEST_ROOT}/${link_target}" "${TARGET}/${metadata}"

            run_scaffold

            [ "${status}" -ne 0 ]
            [[ "${output}" == *"blocking entry in the current working directory: ${metadata} (symbolic links are not allowed)."* ]]
            [ "$(readlink "${TARGET}/${metadata}")" = "${TEST_ROOT}/${link_target}" ]
            [ "$(cat "${TEST_ROOT}/existing/sentinel")" = 'external content' ]
            [ ! -e "${TEST_ROOT}/missing" ]
            [ "$(find "${TARGET}" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]
            assert_no_staging_directory
            rm "${TARGET}/${metadata}"
        done
    done
}

@test "rejects unrecognized hidden directories while preserving all contents" {
    mkdir -p "${TARGET}/.idea/nested" "${TARGET}/.git"
    printf 'keep project settings\n' > "${TARGET}/.idea/nested/config"
    printf 'keep git metadata\n' > "${TARGET}/.git/config"

    run_scaffold

    [ "${status}" -ne 0 ]
    [[ "${output}" == *'blocking entry in the current working directory: .idea;'* ]]
    [ "$(cat "${TARGET}/.idea/nested/config")" = 'keep project settings' ]
    [ "$(cat "${TARGET}/.git/config")" = 'keep git metadata' ]
    [ "$(find "${TARGET}" -mindepth 1 -maxdepth 1 | wc -l)" -eq 2 ]
    assert_no_staging_directory
}

@test "rejects regular files using agent metadata directory names" {
    local metadata
    for metadata in .codex .claude .agents; do
        printf 'keep file\n' > "${TARGET}/${metadata}"

        run_scaffold

        [ "${status}" -ne 0 ]
        [[ "${output}" == *"blocking entry in the current working directory: ${metadata};"* ]]
        [ "$(cat "${TARGET}/${metadata}")" = 'keep file' ]
        [ "$(find "${TARGET}" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]
        assert_no_staging_directory
        rm "${TARGET}/${metadata}"
    done
}

@test "rechecks the destination after staging and preserves newly present files" {
    mkdir -p "${TEST_ROOT}/bin" "${TARGET}/.git"
    printf 'keep git metadata\n' > "${TARGET}/.git/config"
    export SCAFFOLD_TEST_MKTEMP
    SCAFFOLD_TEST_MKTEMP="$(command -v mktemp)"
    cat > "${TEST_ROOT}/bin/mktemp" <<'SHIM'
#!/usr/bin/env bash
set -eu
"${SCAFFOLD_TEST_MKTEMP}" "$@"
printf 'created during staging\n' > appeared.txt
SHIM
    chmod +x "${TEST_ROOT}/bin/mktemp"
    export PATH="${TEST_ROOT}/bin:${PATH}"

    run_scaffold

    [ "${status}" -ne 0 ]
    [[ "${output}" == *'blocking entry in the current working directory: appeared.txt;'* ]]
    [ "$(cat "${TARGET}/appeared.txt")" = 'created during staging' ]
    [ "$(cat "${TARGET}/.git/config")" = 'keep git metadata' ]
    [ "$(find "${TARGET}" -mindepth 1 -maxdepth 1 | wc -l)" -eq 2 ]
    assert_no_staging_directory
}

@test "an installation failure rolls back generated entries and preserves metadata" {
    local metadata
    for metadata in .git .codex .claude .agents; do
        mkdir -p "${TARGET}/${metadata}/nested"
        printf '%s\n' "preserve ${metadata}" > "${TARGET}/${metadata}/nested/config"
    done
    mkdir -p "${TEST_ROOT}/bin"
    export SCAFFOLD_TEST_MV SCAFFOLD_TEST_MV_COUNT
    SCAFFOLD_TEST_MV="$(command -v mv)"
    SCAFFOLD_TEST_MV_COUNT="${TEST_ROOT}/mv-count"
    cat > "${TEST_ROOT}/bin/mv" <<'SHIM'
#!/usr/bin/env bash
set -eu
count=0
if [ -f "${SCAFFOLD_TEST_MV_COUNT}" ]; then
    read -r count < "${SCAFFOLD_TEST_MV_COUNT}"
fi
count=$((count + 1))
printf '%s\n' "${count}" > "${SCAFFOLD_TEST_MV_COUNT}"
if [ "${count}" -eq 2 ]; then
    printf 'simulated move failure\n' >&2
    exit 1
fi
exec "${SCAFFOLD_TEST_MV}" "$@"
SHIM
    chmod +x "${TEST_ROOT}/bin/mv"
    export PATH="${TEST_ROOT}/bin:${PATH}"

    run_scaffold

    [ "${status}" -ne 0 ]
    [[ "${output}" == *'could not install repository entry:'* ]]
    [ "$(find "${TARGET}" -mindepth 1 -maxdepth 1 | wc -l)" -eq 4 ]
    for metadata in .git .codex .claude .agents; do
        [ "$(cat "${TARGET}/${metadata}/nested/config")" = "preserve ${metadata}" ]
    done
    assert_no_staging_directory
}
