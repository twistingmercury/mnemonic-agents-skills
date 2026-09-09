#!/usr/bin/env bats

setup() {
    SCRIPT="/home/jeremy/.codex/skills/dotnet-minimal-api-starter/scripts/scaffold.sh"
    TEST_ROOT="${BATS_TEST_TMPDIR}/case"
    TARGET="${TEST_ROOT}/generated-api"
    mkdir -p "${TARGET}"
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
    [[ "${output}" == *'the current working directory must be empty.'* ]]
    [ "$(cat "${TARGET}/sentinel")" = 'keep me' ]
    [ "$(find "${TARGET}" -mindepth 1 -maxdepth 1 | wc -l)" -eq 1 ]
    assert_no_staging_directory
}

@test "help explains that the empty current directory becomes the repository root" {
    run bash -c 'cd -- "$1" && shift && exec "$@"' _ "${TARGET}" "${SCRIPT}" --help

    [ "${status}" -eq 0 ]
    [[ "${output}" == *'empty current'* ]]
    [[ "${output}" == *'working directory'* ]]
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
