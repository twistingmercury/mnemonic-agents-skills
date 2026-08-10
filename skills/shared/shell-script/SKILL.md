---
name: shell-script
description: Create or modify production-grade shell scripts with automatic BATS test coverage and a bounded verification loop. Use when implementing, refactoring, or fixing shell scripts that should be delivered with executable tests.
---

# Shell Script Creation

Coordinate shell implementation and black-box BATS testing as one workflow. Do not report success until the relevant tests and static checks pass.

## Inputs

Accept from the skill invocation:

- Script purpose and target path
- Required inputs, environment variables, and dependencies
- Expected output, side effects, and error behavior
- Portability requirements, such as supported shells and operating systems

Ask for any missing detail that materially changes the implementation. Infer routine repository conventions from existing scripts and tests.

## Workflow

### 1. Inspect the repository and tools

Read relevant scripts, tests, build conventions, and repository guidance before editing. Check whether required tools are available, including:

- The target shell
- `shellcheck`
- `bats`
- Docker or other external tools only when the requested behavior requires them

Do not install missing tools or dependencies without user approval. If a required tool remains unavailable, continue with safe work that does not depend on it and report the validation gap.

### 2. Select specialists

Select installed agents by declared capability:

- A shell script engineer for implementation and implementation fixes
- A BATS test engineer for black-box tests, test fixes, and test execution

Use each runtime's exact registered agent identifier. Do not assume Claude-style, Codex-style, or filename-derived identifiers. If a matching agent is unavailable, perform that phase directly and note the fallback in the final result.

### 3. Implement the script

Give the shell implementation specialist the complete requirements and relevant repository context. Require it to:

- Follow the repository's established shell and filename conventions
- Prefer portable, readable constructs
- Validate inputs and failures clearly
- Keep control flow flat with guard clauses where practical
- Run the appropriate shell syntax check and ShellCheck
- Return changed paths, commands run, results, and remaining risks

Wait for implementation to finish before creating or updating tests.

### 4. Create and run BATS coverage

Give the BATS specialist the script path, requirements, and expected observable behavior. Require black-box coverage for:

- Successful behavior
- Expected failures and invalid inputs
- Important edge cases and idempotency where relevant
- Standard output, standard error, exit status, and external side effects
- Isolated filesystem or Docker resources with reliable cleanup

Require the specialist to run BATS and ShellCheck and return test paths, commands, results, and reproducible failure details.

### 5. Classify and route failures

The skill orchestrator owns the feedback loop. Do not require one specialist to invoke another.

- **Test defect**: Send the failing assertion, observed behavior, and expected behavior to the BATS specialist. Ask it to correct the test and rerun the suite.
- **Script defect**: Send the failing test, reproduction, observed behavior, and expected behavior to the shell specialist. After the script fix, ask the BATS specialist to rerun the suite.
- **Requirement ambiguity**: Ask the user before choosing behavior that materially changes the contract.
- **Environment or dependency failure**: Report the exact blocker and the validation that remains incomplete.

Continue only while each correction round makes meaningful progress. Stop after three unsuccessful correction rounds, or earlier if the same blocker repeats without new evidence. Never report success with failing tests.

### 6. Perform final verification

Run or confirm the narrowest relevant checks:

- Shell syntax validation for each changed script
- ShellCheck for changed scripts and BATS files
- The focused BATS suite
- Any directly relevant repository test target

Verify that temporary files and external test resources are cleaned up.

### 7. Report the result

Return:

- Script paths created or updated
- BATS test and helper paths created or updated
- Required environment variables and a concise usage example
- Validation commands and results
- Coverage summary
- Fallbacks, unresolved failures, or remaining risks

## Documentation

Use lowercase snake_case for new standalone documentation filenames, except conventional ecosystem filenames.

For versioned standalone documentation, keep `Version`, `Date`, and `Notes` metadata synchronized with the filename. Before editing, inspect Git history and upstream or remote-tracking refs. Never edit a published version; preserve it and create the next version. If publication status is uncertain, treat committed documentation as published. Canonical living files that require fixed paths may be updated in place.

## Completion criteria

Report successful completion only when:

- The requested script behavior is implemented
- BATS coverage exercises the required success, failure, and edge cases
- All focused BATS tests pass
- Shell syntax checks and ShellCheck pass
- Usage and validation results are documented
