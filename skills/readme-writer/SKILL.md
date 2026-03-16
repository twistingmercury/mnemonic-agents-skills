---
name: readme-writer
description: Create or update a concise project README.md using the required template baseline. Use when a project needs a new README, when an existing README is stale or incomplete, or when README structure should be normalized for fast engineer onboarding.
---

# README Writer Skill

Create or update the root `README.md` using `templates/README.template.md` as the minimum required structure.

## Inputs

Collect:

- Project name and purpose
- Maturity level (`Emerging`, `Basic`, or `Mature`)
- Existing documentation to reference
- Build/test/versioning commands that should be runnable

## Workflow

1. Read existing root `README.md` if present.
2. Inspect repository context (`git ls-files` if git repo; otherwise walk directory).
3. Draft README using template sections as required minimum.
4. Add extra sections only when they materially reduce onboarding time.
5. Keep README concise. If setup or getting-started content grows large, move details to a dedicated doc and link to it from README.
6. For versioning, if tags are missing, always fall back to `v0.0.1`.
7. Verify that README has no placeholders, no broken section headings, and commands are realistic for the repo.

## Output Quality Bar

- Use clear, direct prose.
- Prioritize quick project orientation over exhaustive reference material.
- Keep section depth shallow; link out to longer docs instead of expanding inline.
