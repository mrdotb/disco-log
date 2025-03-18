# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](Https://conventionalcommits.org) for commit guidelines.

<!-- changelog -->

## [v1.0.2](https://github.com/mrdotb/disco-log/compare/v1.0.1...v1.0.2) (2025-03-18)




## [v1.0.1](https://github.com/mrdotb/disco-log/compare/v1.0.0...v1.0.1) (2025-03-16)




### Bug Fixes:

* presence: account for handling multiple data frames at once

## [v1.0.0](https://github.com/mrdotb/disco-log/compare/v0.7.0...v1.0.0) (2025-02-01)

### Features:

* go-to-repo: create a link to the repo viewer on discord report

* presence: set basic presence status ð

### Refactor:

* Redesign main modules to enable ad-hoc usage




## [v1.0.0-rc.2](https://github.com/mrdotb/disco-log/compare/v1.0.0-rc.1...v1.0.0-rc.2) (2025-01-26)




### Refactor:

* Redesign main modules to enable ad-hoc usage



## [v1.0.0-rc.1](https://github.com/mrdotb/disco-log/compare/v1.0.0-rc.0...v1.0.0-rc.1) (2025-01-18)




### Bug Fixes:

* correct clause in SSL closed message and handle GenServer logger crash

## [v1.0.0-rc.0](https://github.com/mrdotb/disco-log/compare/v0.8.0-rc.2...v1.0.0-rc.0) (2025-01-10)
### Breaking Changes:

* dynamic tags



## [v0.8.0-rc.2](https://github.com/mrdotb/disco-log/compare/v0.8.0-rc.1...v0.8.0-rc.2) (2025-01-10)




### Bug Fixes:

* presence: handle ssl_closed message

* genserver stop struct remove logger handler

## [v0.8.0-rc.1](https://github.com/mrdotb/disco-log/compare/v0.8.0-rc.0...v0.8.0-rc.1) (2025-01-06)




### Bug Fixes:

* presence: handle receiving no frames from tcp

## [v0.8.0-rc.0](https://github.com/mrdotb/disco-log/compare/v0.7.0...v0.8.0-rc.0) (2025-01-04)




### Features:

* go-to-repo: create a link to the repo viewer on discord report

* presence: set basic presence status ð

* Add Presence

### Bug Fixes:

* presence: handle non-101 response status for ws upgrade request

* presence: do not expect 101 Upgrade response to have data

## [v0.7.0](https://github.com/mrdotb/disco-log/compare/v0.6.0...v0.7.0) (2024-12-09)




### Features:

* Supervisor: override child_spec/1 to automatically use supervisor name as id

### Bug Fixes:

* only limit the final length of inspected metadata

## [v0.6.0](https://github.com/mrdotb/disco-log/compare/v0.5.2...v0.6.0) (2024-11-13)




### Features:

* inspect metadata instead of serializing it

## [v0.5.2](https://github.com/mrdotb/disco-log/compare/v0.5.1...v0.5.2) (2024-10-26)




### Bug Fixes:

* logger handler not handling IO data

## [v0.5.1](https://github.com/mrdotb/disco-log/compare/v0.5.1...v0.5.1) (2024-10-12)




### Bug Fixes:

* write a custom JSON encoder to prevent crashing the handler

## [0.5.0] - 2024-09-12]
- Oban trace improvements
- LiveComponent trace improvements
- Fix double error reporting on some plug errors

## [0.4.0] - 2024-09-01]
- Allow config to disable DiscoLog in env / test environments
- Fix an issue with logger handler and struct

## [0.3.0] - 2024-09-01]
- Bump Req version
- Enable Tesla integration by default

## [0.2.0] - 2024-08-31]
- Fix some bugs
- Add new tesla integration

## [0.1.0] - 2024-08-28]
- Initial release
