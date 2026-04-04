# Worktree-Aware Test Scripts Design

## Goal

Prevent repository test scripts from recursing into local git worktrees under
`./.worktrees/`, then commit the full set of requested changes and remove the
temporary worktree used for the Docker version pinning work.

## Current State

The repository now has a local `.worktrees/` directory that is ignored by git.
The current test scripts still use `find . ...` from the repository root, so
they traverse `./.worktrees/` and re-lint or re-validate files from nested
checkouts.

This causes verification in the main checkout to include duplicate files from
the worktree, which is noisy and can hide whether the primary repository state
passes on its own.

## Scope

In scope:

- Update the existing shell test scripts to ignore `./.worktrees/`
- Keep the filtering change minimal and local to the current scripts
- Verify the main checkout passes the available lint/test commands without
  recursing into the worktree
- Commit all requested changes in the main checkout, including docs and
  `.gitignore`
- Remove the temporary worktree after the commit

Out of scope:

- Refactoring the test scripts beyond the minimum needed path exclusion
- Reworking the broader repository testing strategy
- Running Docker image builds, which remains blocked by missing local container
  tooling

## Files Affected

Primary code and script files:

- `tests/lint-dockerfiles.sh`
- `tests/lint-scripts.sh`
- `tests/validate-json.sh`
- `base/Dockerfile`
- `oh-my-opencode/Dockerfile`
- `get-shit-done/Dockerfile`
- `.gitignore`

Documentation included in the requested commit:

- `docs/superpowers/specs/2026-04-04-docker-version-pinning-design.md`
- `docs/superpowers/plans/2026-04-04-docker-version-pinning.md`
- `docs/superpowers/specs/2026-04-04-worktree-aware-test-scripts-design.md`

## Recommended Approach

Add explicit `grep -v '^./.worktrees/'` filtering to the existing `find`
pipelines in the three test scripts.

This is the smallest correct change because it:

- preserves the current shell script structure
- avoids broader `find -prune` rewrites
- makes the exclusion obvious in each script
- only changes behavior for the local worktree directory

## Data Flow And Behavior

After the change:

1. each test script collects files from the repository root
2. paths under `./.worktrees/` are filtered out before validation/linting
3. verification output reflects only the main checkout contents
4. the main checkout can be committed without worktree noise in test output
5. the temporary worktree can be removed after the commit is complete

## Error Handling

The main failure mode is accidentally over-filtering files and skipping real
repository inputs. To avoid that:

- only exclude the exact `^./.worktrees/` prefix
- leave all other existing filters unchanged
- re-run the repository test entry points after the edit

The commit step should include only the files the user explicitly asked to keep.
The worktree removal step should happen only after a successful commit.

## Testing And Verification

Minimum verification in the main checkout:

- `./tests/lint-dockerfiles.sh`
- `./tests/run-all.sh`
- inspect output to confirm paths under `./.worktrees/` are no longer included
- `git status --short` before commit
- `git status --short` after commit

The Docker build verification gap remains explicit and unchanged because this
environment still lacks a container runtime.

## Success Criteria

The work is complete when all of the following are true:

- the three test scripts no longer recurse into `./.worktrees/`
- main-checkout verification output no longer lists files from the worktree
- the requested files are committed in the main checkout
- the temporary worktree is removed cleanly
- the repository still passes the available lint/test commands in the main
  checkout

## Risks And Tradeoffs

- simple `grep -v` filtering is less structurally elegant than `find -prune`,
  but it is easier to review and safer for this small repo
- the final commit will include process docs under `docs/superpowers/`, which is
  broader than a code-only commit, but that matches the requested scope
- Docker image builds remain unverified until container tooling is available
