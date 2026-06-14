# devcontainer-extender

## Purpose

- Provide a personal, additive layer on top of team-owned `devcontainer.json` files.
- Let a user pick a saved profile and optional feature set per workspace without editing shared repo config.
- Wrap the Dev Container CLI with user defaults like `--docker-path podman`.

## Problem Statement

- Team repositories should stay clean and portable.
- Individual users often want different tools, shells, mounts, and container ergonomics.
- The Dev Container CLI supports feature injection at launch time, but it does not provide a persisted per-workspace preference layer for personal defaults.

## Non-Goals

- Do not replace `devcontainer.json`.
- Do not require users to commit personal tooling preferences to the repository.
- Do not mutate shared config unless the user explicitly exports a profile or overlay.
- Do not become a general package manager.

## Core Concept

`devcontainer-extender` is a small Go CLI that selects a profile, applies personal defaults, optionally adds extra features, and then launches `devcontainer up`.

The tool should treat the repo config as the base layer and the personal profile as an overlay.

## CLI Shape

- `devcontainer-extender up`
- `devcontainer-extender config`
- `devcontainer-extender profile`
- `devcontainer-extender feature`

Recommended default behavior:

- If no profile is selected, open an interactive picker.
- If a profile exists for the current workspace, reuse it without prompting.
- If no feature set exists for the current workspace, open a multi-select picker.

## Interaction Model

### Profile selection

- Single-select.
- Use a terminal picker with search.
- Profiles represent saved bundles of personal defaults.

### Feature selection

- Multi-select.
- Use a checkbox-style terminal UI, not a single-choice picker.
- `fzf --multi` is acceptable for a prototype, but a Go TUI is a better long-term fit.
- Feature selection should allow toggling many items at once.

### Recommended TUI behavior

- `j` / `k` or arrows move.
- `space` toggles a feature.
- `enter` confirms.
- `?` or `h` shows help.
- Search filters the list.

## Configuration

Use XDG config for user-owned state.

Suggested paths:

- `~/.config/devcontainer-extender/config.json`
- `~/.config/devcontainer-extender/state.json`
- `~/.local/share/devcontainer-extender/` for caches, if needed

### Config contents

- Default docker path, usually `podman`.
- Named profiles.
- Feature catalog sources.
- Mount templates.
- Per-workspace remembered selections.

### State keys

- Workspace path.
- Git repository root.
- Optional remote URL.
- Optional profile name.

The tool should remember the last chosen profile and feature set for a workspace so it does not prompt again unless the user asks.

## Profile Model

A profile is a reusable personal preset that can include:

- A set of base features.
- Mounts.
- Remote environment variables.
- Docker path.
- User-data or session-data folder preferences.

Example profiles:

- `operator`
- `agent`
- `ops`

Profile intent examples:

- `operator`: human-focused tooling, `utils-core` plus `utils-human` plus `utils-agent`.
- `agent`: agent-focused tooling, `utils-core` plus `utils-agent`.
- `ops`: admin and maintenance tooling.

## Feature Model

Features should be sourced from:

- The current repository, especially a local `devcontainer-features/` tree.
- An optional personal feature catalog.
- Optional remote feature references.

Feature selection rules:

- Profiles may imply required features.
- Users may add optional features on top.
- Required features should appear selected, locked, or clearly implied.
- The tool should avoid duplicate feature entries.

## Mount Model

- Profiles can define mounts that are personal and workspace-specific.
- Example: mount a host home subdirectory into the container for a named profile.
- Mounts should be synthesized at launch time, not committed into repo config.

## Dev Container CLI Integration

The wrapper should launch the official CLI instead of reimplementing container lifecycle logic.

Known useful flags:

- `--docker-path podman`
- `--workspace-folder`
- `--config`
- `--override-config`
- `--additional-features`
- `--mount`
- `--remote-env`
- `--user-data-folder`
- `--container-session-data-folder`

## Persistence Rules

- Remember the chosen profile per workspace.
- Remember the chosen optional features per workspace.
- Do not ask again on subsequent launches unless the user clears state or changes profiles.
- If the repo changes its base devcontainer config materially, the tool may invalidate stale state.

## Suggested File Layout

- `devcontainer-extender/NOTES.md` for design notes.
- `devcontainer-extender/README.md` for user-facing usage later.
- `devcontainer-extender/cmd/` for Go source when implementation begins.

## Implementation Notes

- A Go CLI is the right boundary once the tool needs state, checkboxes, workspace detection, and config merging.
- Keep the first version small: profile picker, feature picker, config load, state load, and `devcontainer up` execution.
- Prefer additive overlays over file rewriting.

## Open Questions

- Should profile matching key off repo path, git remote, or both?
- Should required profile features be hidden or shown as locked selections?
- Should the tool support exporting a generated overlay file for debugging?
- Should personal feature catalogs support local paths, OCI refs, or both?
