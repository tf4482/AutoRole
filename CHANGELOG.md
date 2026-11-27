# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0] - 2026-11-27

### Added

- `character on|off`, `test`, `reset`, and `debug on|off` chat commands
- "Per character" checkbox on the settings page
- Addon icon in the addon list and compartment menu

### Changed

- Spec roles are saved in `AutoRoleCharDB`; roles from 0.1.x are copied over once
- Shared components updated to the current house versions
- Wider dropdowns on the settings page, without the arrows beside them

### Fixed

- Switching spec while in a group now sets the role of the new spec
- An unknown spec index or saved role no longer causes a Lua error
- `VERSION` matches the release tag v0.1.1

## [0.1.1] - 2026-11-21

### Changed

- Target WoW Forever only (interface 16001)

## [0.1.0] - 2026-11-21

### Added

- Set the group role automatically on joining a group, configurable per dual spec
- Apply a changed role of the active spec right away while in a group
- Settings page, compartment entry, and `/autorole` chat commands
