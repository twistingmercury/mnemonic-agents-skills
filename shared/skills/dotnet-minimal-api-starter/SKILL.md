---
name: dotnet-minimal-api-starter
description: Scaffold the current empty directory as a complete C#/.NET minimal API repository with application, tests, Docker-first build, PostgreSQL, Compose, CI, Helm, Envoy, and automation. Use when a new project should follow the Orders API repository structure; not for modifying an established API.
---

# C# Minimal API Starter

Create a new, runnable repository whose architecture and delivery layers follow the Orders API reference: a focused ASP.NET Core minimal API, tests, PostgreSQL bootstrap, Docker-first verification, CI, and Kubernetes packaging.

Expect the skill to be invoked from the directory that will become the repository root. Before rendering, confirm that the physical current working directory is the intended location and is empty. Never redirect the full scaffold into another directory or overwrite existing contents.

Establish the project name and initial resource/domain name. If not specified, derive PascalCase singular/plural names and a lowercase route/project slug from the user's project concept. The full repository is the default. Use the reduced `base-api` asset only when the user explicitly asks for application files alone.

The full template targets .NET 10 and carries tested package/image pins. If the user requests another .NET version, render first, then update the target framework, package versions, and SDK/runtime images together before verification.

## Reusable templates

For the default full repository, run the bundled renderer:

```sh
scripts/scaffold.sh \
  --api-name <PascalCaseName> \
  --resource-singular <PascalCaseSingular> \
  --resource-plural <PascalCasePlural> \
  --resource-route <lowercase-plural> \
  --project-slug <lowercase-slug> \
  --image-name <registry/owner/api> \
  --database-image-name <registry/owner/database> \
  --ci-branch <branch>
```

Run this command with the intended repository root as the current working directory. The last four options have safe local defaults; provide registry-qualified image names when the generated CI is expected to publish. The renderer stages the entire `assets/full-project` tree beside the current directory, installs it into that existing directory without replacing the directory itself, includes dot-directories, replaces tokens in paths and contents, strips `.tmpl`, and makes shell entrypoints executable.

For application files alone, use the parameterized files in [assets/base-api](assets/base-api), replace every token in its [token guide](assets/base-api/TOKENS.md), and place them under an SDK-created web project.

Both templates provide a coherent single-resource CRUD smoke-test model (`Id` and `Name`). After rendering, adapt the API contract, DTOs, schema, seed data, and tests together to the user's actual domain. Do not retain the example model when it misrepresents the requirements.

Do not deploy, publish images, initialize Git, or create remote resources unless the user separately asks. Scaffolding creates local files only.

The generated local build must not depend on Git having been initialized. Before a valid `HEAD` exists, it uses development image metadata; once committed, it automatically uses commit-derived tags and exact release tags.

## Project shape

Read [the project-shape reference](references/project_shape.md) before creating files. Preserve the responsibilities shown there:

- `Program.cs` is a plain composition root: configuration, dependency injection, OpenAPI, middleware, and endpoint registration.
- `Endpoints/` maps route groups and HTTP semantics only; it delegates business work to an injected handler interface.
- `Handlers/` holds use-case logic and response mapping.
- `DataAccess/` contains the `DbContext` and persistence DTOs; `Models/` contains API contracts/domain-facing types.
- Use typed results, cancellation tokens for database-facing async operations, and explicit validation appropriate to the contract.

Do not add repositories, CQRS infrastructure, MediatR, authentication, or migrations merely because they are common. Add them only when the user asks or the stated requirements require them. Keep the first resource small and coherent.

## Data and runtime defaults

When PostgreSQL persistence is requested, use EF Core with the Npgsql provider, read a named connection string from configuration, and wire it through DI. Supply development-safe configuration examples without committing real secrets. Provide SQL initialization scripts only when the user asks for a seeded database or schema bootstrap; otherwise leave schema management as an explicit next step.

When API documentation is requested, configure the built-in OpenAPI support and a UI compatible with the chosen .NET version. Expose an endpoint that can be used for lightweight health/readiness probes if deployment assets are included.

## Delivery layers

The full scaffold includes:

- root README, ignore files, Makefile, and Docker Compose;
- `build/` multi-stage Docker build, black-box runner, and BATS coverage;
- `database/` PostgreSQL image, migration/bootstrap SQL, scripts, and BATS coverage;
- `scripts/` local analysis entrypoint;
- `.github/workflows/` Docker-first CI that builds/tests once and only publishes that built image from the configured trusted branch;
- `deploy/<project>/` API/PostgreSQL Helm chart and `deploy/envoy/` reverse-proxy chart;
- `src/<ApiName>/`, unit tests, and Docker-backed black-box tests.

Keep image registries, namespaces, credentials, ports, and release names configurable. The included credentials are disposable-development defaults and must be replaced before any shared deployment. NetworkPolicy assumes an enforcing CNI and permits Envoy-labeled pods to reach the API.

## Verification and handoff

After domain adaptation, confirm that no supported template tokens or `.tmpl` suffixes remain. Run `dotnet format` without `--verify-no-changes` on the API, unit-test, and black-box-test project files so whitespace and other automatic formatting corrections are applied before the container build. Then run shell syntax, ShellCheck, and BATS checks for automation, plus Helm lint/template checks.

Only after the formatting pass, run `make build` from the generated repository root. This is the skill's required completion gate: do not report successful skill execution unless `make build` exits successfully. It performs the containerized formatting verification, package audit, compilation, unit tests, runtime image build, and Docker-backed black-box tests. Diagnose and correct scaffold defects exposed by the command, rerun `dotnet format` for affected projects, and then rerun `make build`. If Docker, network access, or another required dependency is unavailable, report that the scaffold was created but the skill did not complete successfully; do not substitute narrower checks for this gate.

Summarize the generated layout, configuration the user must set, and exact commands to run the API and its tests. Link to the key entry points rather than reproducing every generated file.
