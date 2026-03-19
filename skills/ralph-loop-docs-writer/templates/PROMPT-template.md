# Ralph Loop Prompt for [Project Name]

You are executing one Ralph loop cycle for the `<repo>` repository.
Follow the repository-specific rules below.

## Objective

Complete exactly one unchecked cycle from the active PRD, verify it, update the
PRD state, append a progress entry, and stop.

## Inputs

You will be given:

- the active PRD
- the current progress log, if one exists
- the repository working tree

The active PRD for this project is expected to be:

- `<path/to/PRD.md>`

The primary supporting documents are:

- `<doc1>`
- `<doc2>`

The canonical progress log path for this repository is:

- `<path/to/progress.txt>`

If `<path/to/progress.txt>` does not exist, create it when completing
the first cycle.

## Non-Negotiable Rules

1. Execute exactly one PRD cycle.
2. Work only on the first unchecked `- [ ]` cycle in the PRD.
3. Do not skip ahead.
4. Do not combine multiple cycles into one run.
5. Search the repository before editing. Do not assume code or files are
   missing.
6. Respect the cycle's `Agent`, `Files`, `Steps`, and `Verify` fields.
7. Keep changes scoped to the selected cycle.
8. Run verification before marking the cycle complete.
9. Update the PRD and progress log only after the cycle passes verification.
10. Stop after finishing that one cycle.

## Repo-Specific Build and Test Rules

[Add language/toolchain-specific rules here. Examples:]

<!-- Go projects:
- Run `go test ./...` for all unit test verification.
- Run `go vet ./...` and `golangci-lint run` after any source change.
- Use `go build ./...` to verify compilation.
-->

<!-- Node/React projects:
- The canonical build path is `./build/build.sh`.
- Use `npm run build`, `npm run test`, and `npm run e2e` as appropriate.
- CI must stay thin and call repository scripts instead of embedding logic inline.
-->

## Ralph Loop Procedure

### Step 1: Read the PRD and select the cycle

- Open `<path/to/PRD.md>`.
- Find the first unchecked `- [ ]` cycle under `## Implementation Plan`.
- Extract:
  - cycle title
  - cycle description
  - `Agent`
  - `Files`
  - `Steps`
  - `Verify`

If no unchecked cycle exists, stop and report that the PRD is complete.

### Step 2: Read supporting context

- Read the design and stack documents relevant to the selected cycle.
- Read the progress log if it exists.
- Search the codebase before editing anything.

### Step 3: Plan narrowly

- Form a minimal plan that completes only the selected cycle.
- Do not plan future cycles.
- Do not expand scope beyond the listed files and directly necessary support
  files.

### Step 4: Delegate or execute

- If your runtime supports subagents, delegate to the cycle's named `Agent`.
- If not, execute the cycle directly while still honoring the assigned role.
- Keep the implementation bounded to the selected cycle.

### Step 5: Verify

Run the cycle's `Verify` command exactly as written unless it is impossible in
the current environment.

[Add any baseline checks applicable to this project. Examples:]

<!-- Go baseline:
1. `go vet ./...` — no vet errors
2. `go test ./...` — all tests pass
3. `golangci-lint run` — no lint errors
-->

<!-- React/Node baseline:
1. `npx tsc --noEmit` — type check must pass
2. `npx eslint src/` — no lint errors
3. `npm run test` — all tests pass
-->

If any check fails:

- fix the problem if it is within the cycle scope
- rerun verification
- do not mark the cycle complete until all checks pass

### Step 6: Commit the changes

After verification passes, stage and commit all files produced or modified by
the cycle:

- stage only the files listed in the cycle's `Files` field and any directly
  necessary support files that the cycle required
- use a concise commit message that names the cycle number and title
- do not skip hooks or sign flags
- if the commit fails, fix the issue and recommit before proceeding

### Step 7: Update project records

After the commit succeeds:

- change the selected PRD cycle from `- [ ]` to `- [x]`
- append a concise entry to `<path/to/progress.txt>`
- stage and commit the updated PRD and progress log as a follow-up commit

Each progress entry should include:

- cycle number and title
- date
- summary of work completed
- verification performed
- important follow-up notes, if any

### Step 8: Report and stop

At the end of the loop:

- report what changed
- report what verification passed
- report the next unchecked cycle
- stop

Do not continue into the next cycle.

## Failure Modes to Avoid

- completing more than one cycle in one run
- editing files unrelated to the selected cycle
- skipping repository search and duplicating existing code
- marking a cycle complete before verification passes
- embedding complex build logic directly in CI YAML instead of repository scripts
- refactoring architecture that the PRD did not ask to change

## Output Contract

Your final response for a completed loop should contain:

- the completed cycle number and title
- the files changed
- the verification that passed
- the next unchecked cycle

If you could not complete the cycle, state exactly why and do not mark it done.
