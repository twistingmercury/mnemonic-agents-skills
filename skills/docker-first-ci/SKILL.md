---
name: docker-first-ci
description: Implement and harden Docker-first CI/CD pipelines in repository workflows. Use when users ask to set up or fix CI/CD behavior, enforce Docker image build-and-test in CI, gate CD on trusted events, publish immutable artifacts, and deploy/promote without rebuilding.
---

# Docker-First CI/CD Implementation

## Overview

Implement Docker-first CI/CD so CI builds and validates the image once, then CD promotes that exact immutable output.

## Implementation Workflow

1. Inspect current implementation:
- Build entrypoints (`build.sh`, `Makefile`, `Dockerfile`)
- CI and CD workflow files
- Test orchestration (compose/test runners)

2. Implement CI:
- Build runtime image from Dockerfile.
- Run quality gates and unit tests in the build container stage.
- Run integration or E2E tests before publish.
- Fail on any gate failure.

3. Implement CI-to-CD handoff:
- Publish image/artifact once in CI.
- Pass digest/tag/commit metadata forward.
- Require CD to resolve and promote CI output only.
- Do not rebuild app image in CD.

4. Implement release gates:
- Gate CD on trusted events only (push/tag/approval per policy).
- Keep branch/tag policy explicit (for example `latest` only from `main`).
- Block PR-originated publish paths unless explicitly required.

5. Validate end to end:
- Confirm local and CI build/test behavior match.
- Confirm CD runs only under policy gates.
- Confirm failed tests prevent artifact publication.
- Confirm published tags/digests match CI outputs.

## Rules

1. Separate CI and CD responsibilities:
- CI: build, test, scan, package, publish immutable artifact.
- CD: fetch artifact, deploy/promote, verify, rollback/promote decision.

2. Keep policy and mechanism distinct:
- Policy: branch/tag/approval and promotion rules.
- Mechanism: concrete actions, commands, and artifact transport.

3. Keep changes deterministic and minimal:
- Pin action/tool versions where practical.
- Avoid environment-dependent branching in build scripts.
- Preserve existing release intent.
- Patch only the rules needed to enforce Docker-first flow and gates.

## References

- Project-specific flow example: `_draft-skills/docker-first-ci-cd-implementation/references/example-go-ci-cd-diagram.md`
- Organization reference example: `_draft-skills/docker-first-ci-cd-implementation/references/docker-first-ci-cd-diagram.md`
- Example build entrypoint: `_draft-skills/docker-first-ci-cd-implementation/references/example-build.sh`
- Example Dockerfile: `_draft-skills/docker-first-ci-cd-implementation/references/example-Dockerfile`
- Example CI workflow: `_draft-skills/docker-first-ci-cd-implementation/references/example-ci.yaml`
- Example CD workflow: `_draft-skills/docker-first-ci-cd-implementation/references/example-cd.yaml`
