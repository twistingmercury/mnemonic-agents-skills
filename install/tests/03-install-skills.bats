#!/usr/bin/env bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    TEST_TMP="$(mktemp -d)"
    export SKILL_SOURCE="${TEST_TMP}/skills"
    export SKILLS_DIR="${TEST_TMP}/target/"
    export FORCE=0
    export PROJ_ROOT="${TEST_TMP}"
    export SETUP_DIR="${SCRIPT_DIR}"

    # shellcheck source=../scripts/03-install-skills.sh
    # Entry point guard prevents install_skills from running on source
    source "${SCRIPT_DIR}/scripts/03-install-skills.sh"
}

teardown() {
    rm -rf "${TEST_TMP}"
}

# ---------------------------------------------------------------------------
# validate_environment
# ---------------------------------------------------------------------------

@test "validate_environment: fails when SKILL_SOURCE dir is missing" {
    SKILL_SOURCE="${TEST_TMP}/nonexistent"
    run validate_environment
    [ "$status" -ne 0 ]
}

@test "validate_environment: succeeds when SKILL_SOURCE dir exists" {
    mkdir -p "${SKILL_SOURCE}"
    run validate_environment
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# list_repo_skills
# ---------------------------------------------------------------------------

@test "list_repo_skills: returns subdirectory names from skill source" {
    mkdir -p "${SKILL_SOURCE}/arch-docs" "${SKILL_SOURCE}/prime"

    run list_repo_skills
    [ "$status" -eq 0 ]
    [[ "$output" == *"arch-docs"* ]]
    [[ "$output" == *"prime"* ]]
}

# ---------------------------------------------------------------------------
# is_repo_managed_skill
# ---------------------------------------------------------------------------

@test "is_repo_managed_skill: returns 0 when skill is in list" {
    run is_repo_managed_skill "prime" "$(printf 'arch-docs\nprime')"
    [ "$status" -eq 0 ]
}

@test "is_repo_managed_skill: returns non-zero when skill is not in list" {
    run is_repo_managed_skill "user-skill" "$(printf 'arch-docs\nprime')"
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# remove_repo_managed_skills
# ---------------------------------------------------------------------------

@test "remove_repo_managed_skills: returns non-zero when SKILLS_DIR is empty string" {
    SKILLS_DIR=""
    run remove_repo_managed_skills
    [ "$status" -ne 0 ]
}

@test "remove_repo_managed_skills: returns non-zero when SKILLS_DIR is /" {
    SKILLS_DIR="/"
    run remove_repo_managed_skills
    [ "$status" -ne 0 ]
}

@test "remove_repo_managed_skills: no-op when SKILLS_DIR does not exist" {
    SKILLS_DIR="${TEST_TMP}/nonexistent/"
    run remove_repo_managed_skills
    [ "$status" -eq 0 ]
}

@test "remove_repo_managed_skills: removes repo-managed skill directory when FORCE=1" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}"
    ln -s "${SKILL_SOURCE}/prime" "${SKILLS_DIR}/prime"

    # FORCE=1 required: with FORCE=0, the keep-current-symlink guard would preserve
    # an up-to-date symlink rather than removing it
    FORCE=1
    run remove_repo_managed_skills
    [ "$status" -eq 0 ]
    [ ! -e "${SKILLS_DIR}/prime" ]
}

@test "remove_repo_managed_skills: preserves user skill not in repo list" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}/user-skill"

    run remove_repo_managed_skills
    [ "$status" -eq 0 ]
    [ -d "${SKILLS_DIR}/user-skill" ]
}

@test "remove_repo_managed_skills: keeps current symlink when FORCE=0" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}"
    ln -s "${SKILL_SOURCE}/prime" "${SKILLS_DIR}/prime"

    FORCE=0
    run remove_repo_managed_skills
    [ "$status" -eq 0 ]
    [ -L "${SKILLS_DIR}/prime" ]
}

# ---------------------------------------------------------------------------
# symlink_repo_skills
# ---------------------------------------------------------------------------

@test "symlink_repo_skills: returns non-zero when SKILLS_DIR is empty string" {
    SKILLS_DIR=""
    run symlink_repo_skills
    [ "$status" -ne 0 ]
}

@test "symlink_repo_skills: returns non-zero when SKILLS_DIR is /" {
    SKILLS_DIR="/"
    run symlink_repo_skills
    [ "$status" -ne 0 ]
}

@test "symlink_repo_skills: creates symlink for new skill" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}"

    run symlink_repo_skills
    [ "$status" -eq 0 ]
    [ -L "${SKILLS_DIR}/prime" ]
}

@test "symlink_repo_skills: skips existing symlink" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}"
    ln -s "${SKILL_SOURCE}/prime" "${SKILLS_DIR}/prime"

    run symlink_repo_skills
    [ "$status" -eq 0 ]
    [[ "$output" == *"Already installed"* ]]
}

@test "symlink_repo_skills: skips existing non-symlink path" {
    mkdir -p "${SKILL_SOURCE}/prime" "${SKILLS_DIR}/prime"

    run symlink_repo_skills
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping existing non-symlink"* ]]
    [ ! -L "${SKILLS_DIR}/prime" ]
}
