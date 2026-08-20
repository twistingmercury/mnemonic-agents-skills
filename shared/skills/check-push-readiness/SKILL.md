---
name: check-push-readiness
description: Assess whether local commits on the current branch are ready to push to their configured remote branch. Use when asked whether a commit, set of commits, or branch is ready to push. Limit the verdict to the exact committed content that the next Git push would transfer.
---

# Check Push Readiness

## Apply Guardrails

- Operate read-only.
- Do not edit, stage, commit, fetch into the repository, push, or fix findings without explicit approval.
- Do not create tracked readiness or review documents.
- Re-read repository and remote state before the final verdict if concurrent edits are possible.

## Establish Push Scope

- Read applicable `AGENTS.md`, contribution guidance, development documentation, and repository-defined validation commands.
- Identify the current branch, configured upstream, push remote, and remote branch.
- Resolve the live remote branch SHA with a read-only query such as `git ls-remote`; do not rely solely on possibly stale remote-tracking refs.
- Identify the exact commits that the configured push would transfer.
- Report `NO-GO` when the destination or commit range is ambiguous.
- Report `NOTHING TO PUSH` when local `HEAD` matches the live remote ref and no commits would transfer.

If the live remote SHA is unavailable locally, use a read-only hosting API or a disposable temporary clone to compare history. Do not update local refs merely to perform the check.

## Inspect Repository State

Inspect:

- Branch, `HEAD`, upstream, push configuration, and remote URLs.
- Ahead/behind state against the live remote ref.
- Staged, unstaged, untracked, and relevant ignored files.
- Unmerged paths, submodule changes, and Git LFS state when applicable.

Distinguish committed content from dirty worktree content. Dirty files are not part of the push, but flag them when they indicate that a commit may be incomplete, generated outputs are stale, tests may inspect unintended content, or the user may believe those files are included.

Verify that the live remote commit is an ancestor of local `HEAD`. Report `NO-GO` for divergence, a non-fast-forward push, rewritten published history, or any case requiring force.

## Review the Exact Commits

Inspect every unpushed commit and the full aggregate diff against the live remote commit.

Check commit metadata for:

- Clear and policy-compliant subjects and bodies.
- Correct authorship and signing when required.
- Accidental fixup, squash, revert, or merge commits.
- Issue references, attribution, and trailers required by repository policy.

Check the full diff for:

- Secrets, credentials, private keys, tokens, or sensitive data.
- Conflict markers, debug code, temporary instrumentation, or disabled checks.
- Accidental binaries, archives, large files, generated artifacts, or local configuration.
- Unrelated changes, incomplete refactors, stale generated files, and missing migrations.
- Correctness defects, security risks, compatibility breaks, and inadequate tests.
- Unexpected file modes, renames, deletions, submodule pointers, or dependency changes.

Avoid reproducing discovered secrets in output. Identify only the affected file and remediation category.

## Validate the Committed Tree

- Run repository-prescribed formatting, linting, static analysis, tests, builds, and documentation checks proportional to the pushed diff.
- Prefer validation of exact `HEAD`, not a dirty working tree.
- Use a disposable temporary clone when dirty files could affect results and exact committed-tree validation is material.
- Record the commands, results, skipped checks, and environmental limitations.
- Treat required failed or unverified checks as `NO-GO`.
- Use focused correctness review or a relevant language specialist when changed files require expertise beyond the prescribed checks.

## Report Readiness

Report findings first, ordered by severity. For each finding, state:

- The concrete problem.
- The affected commit or file.
- Evidence sufficient to verify it.
- Why it blocks or weakens push readiness.

Then issue exactly one verdict:

- `GO`: The exact unpushed commits are reviewed, validation is sufficient, and the push is fast-forward.
- `NO-GO`: A blocker, divergence, ambiguous destination, incomplete commit signal, or required unverified check remains.
- `NOTHING TO PUSH`: The configured live remote branch already points to local `HEAD`.

Conclude with the exact remote destination, live remote SHA, local `HEAD`, unpushed commit range, validation performed, and any checks not completed. Do not push or fix findings without explicit approval.
