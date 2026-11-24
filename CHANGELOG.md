# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed

- Switching spec while in a group now sets the role of the new spec
- An unknown spec index or saved role no longer causes a Lua error

## [0.1.1] - 2026-11-21

### Changed

- Target WoW Forever only (interface 16001)

## [0.1.0] - 2026-11-21

### Added

- Set the group role automatically on joining a group, configurable per dual spec
- Apply a changed role of the active spec right away while in a group
- Settings page, compartment entry, and `/autorole` chat commands
