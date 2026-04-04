# Docker Version Pinning Design

## Goal

Replace static inline package/tool versions and floating package installs in the
repository's Docker build scripts with explicit top-of-file version variables,
and update those variables to current stable releases.

## Current State

The current Docker build scripts mix several versioning styles:

- `base/Dockerfile` hardcodes versions inline for `hadolint`, `nvm`,
  `opencode-ai`, and `typescript`
- `get-shit-done/Dockerfile` intentionally installs `get-shit-done-cc@latest`
- `oh-my-opencode/Dockerfile` invokes `npx oh-my-opencode install` without an
  explicit package version
- Other variant Dockerfiles currently clone repositories without release tags

This makes version bumps harder to audit, obscures which external dependencies
are intentionally pinned, and allows some builds to drift over time.

## Scope

In scope:

- Add top-of-file `ARG` declarations for externally installed tools/packages
  that currently use inline versions or floating installs
- Update those version variables to current stable releases
- Replace version literals in install commands with references to those `ARG`s
- Keep version declarations in the Dockerfile where they are consumed
- Verify the affected images still build and pass existing repository checks

Out of scope:

- Pinning Ubuntu `apt` packages to distro package versions
- Refactoring Dockerfile structure beyond the minimum needed for version
  variables
- Reworking git-based skill repository clones to use tags or SHAs unless a
  concrete pinned-release requirement appears during implementation

## Files Affected

Primary files:

- `base/Dockerfile`
- `get-shit-done/Dockerfile`
- `oh-my-opencode/Dockerfile`

Potential verification/support files only if required by the implementation:

- `Makefile`
- `README.md`
- `tests/` scripts if existing checks need minor updates for the new build
  arguments

## Recommended Approach

Use top-of-file Docker `ARG`s in each Dockerfile that installs external tools.
This keeps the change local, small, and obvious to maintainers reading a single
build script.

Planned variable additions:

- `base/Dockerfile`
  - `NVM_VERSION`
  - `HADOLINT_VERSION`
  - `OPENCODE_AI_VERSION`
  - `TYPESCRIPT_VERSION`
- `get-shit-done/Dockerfile`
  - `GET_SHIT_DONE_CC_VERSION`
- `oh-my-opencode/Dockerfile`
  - `OH_MY_OPENCODE_VERSION`

If implementation uncovers any other floating install of an external tool or
package in a Docker build script, and that install is performed via npm or a
versioned download URL rather than `git clone`, it should be treated the same
way: define a top-of-file `ARG`, then use that variable in the install command.

## Version Selection Rules

During implementation, each variable should be set to the latest stable version
available from the tool's official release channel at the time of change.

Preferred sources:

- GitHub releases for GitHub-hosted tools such as `hadolint` and `nvm`
- npm registry for npm packages such as `opencode-ai`, `typescript`,
  `get-shit-done-cc`, and `oh-my-opencode`

Rules:

- Prefer stable releases over prereleases, betas, or release candidates
- Use exact pinned versions, not ranges or tags like `latest`
- Keep the version string format compatible with the existing install command
  syntax

## Data Flow And Behavior

The build behavior should remain functionally the same except for version
selection becoming explicit and deterministic.

Expected build flow after the change:

1. Docker reads version `ARG`s declared at the top of the Dockerfile
2. Install commands interpolate those `ARG`s into download or `npm` commands
3. Builds produce repeatable tool versions unless a maintainer intentionally
   changes an `ARG`

## Error Handling

The change should not introduce new runtime behavior. The main failure mode is a
bad version pin causing a download or install failure during `docker build`.

To manage that risk:

- Validate each selected version against its source before editing the Dockerfile
- Rebuild the affected images after the edits
- Prefer minimal edits so any version-related failure is isolated and easy to
  diagnose

## Testing And Verification

Implementation should verify both syntax and build behavior.

Minimum verification:

- Run the repository's Dockerfile lint/check workflow if available
- Build the affected images from the repository targets
- Run the existing test entry points that cover Docker builds if present

Practical verification target:

- `make test-dockerfiles`
- `make test`
- `docker build -t opencode-base base/`
- `docker build -t opencode-oh-my-opencode oh-my-opencode/`
- `docker build -t opencode-get-shit-done get-shit-done/`

If full verification is too expensive in one pass, the base image build and the
two directly changed variant builds are the minimum required checks.

## Success Criteria

The work is complete when all of the following are true:

- No targeted Docker build script contains inline hardcoded package/tool
  versions where a top-of-file variable should be used
- No targeted Docker build script uses floating npm package installs such as
  `@latest`
- All newly introduced version variables are set to explicit stable versions
- Affected images build successfully
- Existing repository checks relevant to Dockerfiles still pass

## Risks And Tradeoffs

- Pinning versions improves reproducibility but requires explicit maintenance on
  future updates
- `oh-my-opencode` or `get-shit-done-cc` may have package-version behavior that
  differs from the currently floating install path; verification must catch that
- Git clone dependencies remain floating in this design, which is intentional to
  keep scope focused on package/tool installs rather than repository source
  pinning
