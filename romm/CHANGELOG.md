# Changelog

All notable changes to this add-on will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## romm 0.1.26 - 2026-01-27

### Changes

- No changes

## romm 0.1.25 - 2026-01-26

### Changes

- No changes

## romm 0.1.24 - 2026-01-26

### Changes

- No changes

## romm 1.0.0 - 2026-01-27

### ⚠️ BREAKING CHANGES

This is a **major breaking change**. Please read carefully before upgrading.

#### What Changed

- **Removed Ingress support**: ROMM no longer appears in Home Assistant sidebar
- **Direct port access**: ROMM now exposes port 5999 (configurable) directly to your network
- **Base path changed**: Application runs at root path `/` instead of `/romm`
- **Security rating decreased**: No longer benefits from Ingress +2 security points

#### Migration Guide

**Before Upgrading:**

1. Note your current ROMM configuration (database, auth key, etc.)
2. Ensure you have network access to Home Assistant on port 5999
3. Understand that sidebar access will be removed

**After Upgrading:**

1. Access ROMM at: `http://YOUR_HA_IP:5999` (replace YOUR_HA_IP with your Home Assistant IP)
2. Bookmark the URL for easy access
3. Consider setting up a reverse proxy with authentication for enhanced security
4. Optional: Configure a different port in add-on settings if 5999 conflicts

**If you need to change the port:**

1. Go to Add-on Configuration tab
2. Set `port` option to your desired port (1024-65535)
3. Save configuration and restart the add-on
4. Access at new URL: `http://YOUR_HA_IP:YOUR_PORT`

#### Why This Change?

- Greater flexibility for users who prefer direct access
- Better compatibility with reverse proxy setups (Traefik, nginx Proxy Manager)
- Improved integration with external authentication systems (Authelia, etc.)
- Standard deployment pattern for self-hosted applications

### Added

- Configurable port option (default: 5999)
- Web UI URL template for "Open Web UI" button in add-on interface
- Direct port exposure via Home Assistant's port mapping

### Removed

- Ingress support (no longer appears in Home Assistant sidebar)
- Ingress IP restriction (172.30.32.2)
- Base path `/romm` prefix - all routes now at root `/`
- Sidebar panel icon

### Changed

- Base path from `/romm` to `/` (root)
- Port configuration from `ingress_port` to configurable `port` option
- Security profile (lost Ingress +2 security points)
- Access method from sidebar to direct URL


---

## romm 0.1.23 - 2026-01-26

### Changes

- No changes

## romm 0.1.22 - 2026-01-26

### Changes

- No changes

## romm 0.1.21 - 2026-01-26

### Changes

- No changes

## romm 0.1.20 - 2026-01-26

### Changes

- No changes

## romm 0.1.19 - 2026-01-26

### Changes

- No changes

## romm 0.1.18 - 2026-01-26

### Changes

- No changes

## romm 0.1.17 - 2026-01-26

### Changes

- No changes

## romm 0.1.16 - 2026-01-26

### Changes

- No changes

## romm 0.1.15 - 2026-01-26

### Changes

- No changes

## romm 0.1.14 - 2026-01-26

### Changes

- No changes

## romm 0.1.13 - 2026-01-26

### Changes

- No changes

## romm 0.1.12 - 2026-01-26

### Changes

- No changes

## romm 0.1.11 - 2026-01-26

### Changes

- No changes

## romm 0.1.10 - 2026-01-26

### Changes

- No changes

## romm 0.1.9 - 2026-01-26

### Changes

- No changes

## romm 0.1.8 - 2026-01-26

### Changes

- No changes

## romm 0.1.7 - 2026-01-26

### Changes

- No changes

## romm 0.1.6 - 2026-01-25

### Changes

- No changes

## romm 0.1.5 - 2026-01-25

### Changes

- No changes

## romm 0.1.4 - 2026-01-25

### Changes

- No changes

## romm 0.1.3 - 2026-01-25

### Changes

- No changes

## romm 0.1.2 - 2026-01-25

### Changes

- No changes

## romm 0.1.1 - 2026-01-25

### Changes

- No changes

## romm 0.1.0 - 2026-01-25

### Changes

- Test @rigerc (#1)

## [0.5.0](https://github.com/rigerc/home-assistant-addons/compare/Romm-0.4.0...Romm-0.5.0) (2026-02-05)


### ✨ Features

* **ci:** enhance addon manifest generation and README updates ([8d5c91b](https://github.com/rigerc/home-assistant-addons/commit/8d5c91b48392a4b82387b32f3b3834906b5237f7))
* Enhance addon discovery with entrypoint analysis ([1bfe059](https://github.com/rigerc/home-assistant-addons/commit/1bfe0595e8ad4ac046db0aad5bbd7b2fef20da5d))
* Improve ROMM access and configuration ([0c81a20](https://github.com/rigerc/home-assistant-addons/commit/0c81a206bc0e958983864da7e493b855abed5109))
* **migrations:** add initial database migration script ([d515e8f](https://github.com/rigerc/home-assistant-addons/commit/d515e8f10c83ce8001d55a7cdf4f1bc65e923b79))
* **migrations:** add shellcheck directive to migration script ([a7bc4d8](https://github.com/rigerc/home-assistant-addons/commit/a7bc4d82a4d0ec649332cf89fab4dc5f0aba20dd))


### 🐛 Bug Fixes

* add missing document start markers to YAML files ([e6c631e](https://github.com/rigerc/home-assistant-addons/commit/e6c631ea3fcd7cc720164b34ebe75f036eee9df2))
* **ci:** add required runs-on to reusable workflow jobs ([086a43b](https://github.com/rigerc/home-assistant-addons/commit/086a43b7d36158de7fc2eb5510a5cc398920b0cc))
* **nginx:** add shellcheck directive to run script ([594c2f5](https://github.com/rigerc/home-assistant-addons/commit/594c2f5b3bfd7fb43cc7296704bac42e895e898e))
* **setup:** add shellcheck directive for improved script compatibility ([a13c497](https://github.com/rigerc/home-assistant-addons/commit/a13c497176f762ea562741b6b8253f349e4db1dd))
* **setup:** update entry for domain branch check to use python3 ([990f02f](https://github.com/rigerc/home-assistant-addons/commit/990f02f6de0dc812d069796b28fbdae70565abfa))


### 🧰 Maintenance

* release main ([#29](https://github.com/rigerc/home-assistant-addons/issues/29)) ([2801983](https://github.com/rigerc/home-assistant-addons/commit/2801983d3d73c91d5c0117d69a45cc4a48ead734))
* release main ([#30](https://github.com/rigerc/home-assistant-addons/issues/30)) ([e18b112](https://github.com/rigerc/home-assistant-addons/commit/e18b11293ab11e642234877e0365e01ca97e40ea))
* release main ([#31](https://github.com/rigerc/home-assistant-addons/issues/31)) ([83ca58c](https://github.com/rigerc/home-assistant-addons/commit/83ca58c8d69398ce49843c707c5a11734575dd44))
* **rootfs:** add shellcheck directives to service scripts ([320397e](https://github.com/rigerc/home-assistant-addons/commit/320397e58111c1e2101f7dbb59e1a002da58c05d))
* update addon manifest and configs [skip ci] ([b90cb44](https://github.com/rigerc/home-assistant-addons/commit/b90cb44dc225abab258d7418dc2ce72b09d44880))
* update addon manifest and configs [skip ci] ([2b97d4c](https://github.com/rigerc/home-assistant-addons/commit/2b97d4cfba072d9c75c266090fe33223f2f672c6))


### ♻️ Refactoring

* **ci:** clean up comments in setup scripts ([042daac](https://github.com/rigerc/home-assistant-addons/commit/042daacf0c3f4d2f8bac30406da95a4265fec2d4))
* **migrations:** remove unused comment from migration script ([13c359f](https://github.com/rigerc/home-assistant-addons/commit/13c359f9489b9677407b9fff024e5add3591fea5))

## [0.4.0](https://github.com/rigerc/home-assistant-addons/compare/romm-v0.3.0...romm-v0.4.0) (2026-02-04)


### Features

* Add README templates for add-ons ([5604e5a](https://github.com/rigerc/home-assistant-addons/commit/5604e5a2ec27b602bde11b2c305b799cb57d2fce))
* **ci:** enhance addon manifest generation and README updates ([8d5c91b](https://github.com/rigerc/home-assistant-addons/commit/8d5c91b48392a4b82387b32f3b3834906b5237f7))
* Enhance add-on metadata extraction and display ([e7fdab1](https://github.com/rigerc/home-assistant-addons/commit/e7fdab186dc7662181d497d71eb5eedc4564d23b))
* Enhance addon discovery with entrypoint analysis ([1bfe059](https://github.com/rigerc/home-assistant-addons/commit/1bfe0595e8ad4ac046db0aad5bbd7b2fef20da5d))
* Enhance CI/CD and local development tooling ([0ff50a6](https://github.com/rigerc/home-assistant-addons/commit/0ff50a6319a7585458eee376a00690e25db33b01))
* Improve ROMM access and configuration ([0c81a20](https://github.com/rigerc/home-assistant-addons/commit/0c81a206bc0e958983864da7e493b855abed5109))


### Bug Fixes

* **setup:** add shellcheck directive for improved script compatibility ([a13c497](https://github.com/rigerc/home-assistant-addons/commit/a13c497176f762ea562741b6b8253f349e4db1dd))
* **setup:** update entry for domain branch check to use python3 ([990f02f](https://github.com/rigerc/home-assistant-addons/commit/990f02f6de0dc812d069796b28fbdae70565abfa))


### Maintenance

* release main ([#29](https://github.com/rigerc/home-assistant-addons/issues/29)) ([2801983](https://github.com/rigerc/home-assistant-addons/commit/2801983d3d73c91d5c0117d69a45cc4a48ead734))
* release main ([#30](https://github.com/rigerc/home-assistant-addons/issues/30)) ([e18b112](https://github.com/rigerc/home-assistant-addons/commit/e18b11293ab11e642234877e0365e01ca97e40ea))
* update addon manifest and configs [skip ci] ([b90cb44](https://github.com/rigerc/home-assistant-addons/commit/b90cb44dc225abab258d7418dc2ce72b09d44880))
* update addon manifest and configs [skip ci] ([2b97d4c](https://github.com/rigerc/home-assistant-addons/commit/2b97d4cfba072d9c75c266090fe33223f2f672c6))
* update addon metadata [skip ci] ([18eaa08](https://github.com/rigerc/home-assistant-addons/commit/18eaa082871ac2bbf47b3306db2044fa929146f3))
* update addon metadata [skip ci] ([8d52386](https://github.com/rigerc/home-assistant-addons/commit/8d5238651c50d81a497cd0e0f0b42f4c58d74857))
* Update config and linting ([0bac62d](https://github.com/rigerc/home-assistant-addons/commit/0bac62dad01cc3b508c76b4490018efa24ed9a73))


### Refactoring

* Centralize README generation with gomplate ([b7651da](https://github.com/rigerc/home-assistant-addons/commit/b7651da22f99f031439a9ce5450f711ba89cfdee))
* **ci:** clean up comments in setup scripts ([042daac](https://github.com/rigerc/home-assistant-addons/commit/042daacf0c3f4d2f8bac30406da95a4265fec2d4))
* Improve Renovate config and Dockerfile practices ([002d2d5](https://github.com/rigerc/home-assistant-addons/commit/002d2d51532b66ae261e54e04b7e6bf45a7c9033))
* Standardize project URL extraction in build files ([3fd1b04](https://github.com/rigerc/home-assistant-addons/commit/3fd1b04a22cafe1b9daa173f1cfa094985f6ebd4))
* Update add-on versioning and build process ([2f715f5](https://github.com/rigerc/home-assistant-addons/commit/2f715f58632953ba952feb4dd05216547e362f74))

## [0.3.0](https://github.com/rigerc/home-assistant-addons/compare/romm-v0.2.0...romm-0.3.0) (2026-02-03)


### ✨ New features

* **ci:** enhance addon manifest generation and README updates ([8d5c91b](https://github.com/rigerc/home-assistant-addons/commit/8d5c91b48392a4b82387b32f3b3834906b5237f7))


### 🧰 Maintenance

* update addon manifest and configs [skip ci] ([2b97d4c](https://github.com/rigerc/home-assistant-addons/commit/2b97d4cfba072d9c75c266090fe33223f2f672c6))

## [0.2.0](https://github.com/rigerc/home-assistant-addons/compare/romm-0.1.26...romm-v0.2.0) (2026-02-03)


### ✨ New features

* Add README templates for add-ons ([5604e5a](https://github.com/rigerc/home-assistant-addons/commit/5604e5a2ec27b602bde11b2c305b799cb57d2fce))
* Enhance add-on metadata extraction and display ([e7fdab1](https://github.com/rigerc/home-assistant-addons/commit/e7fdab186dc7662181d497d71eb5eedc4564d23b))
* Enhance addon discovery with entrypoint analysis ([1bfe059](https://github.com/rigerc/home-assistant-addons/commit/1bfe0595e8ad4ac046db0aad5bbd7b2fef20da5d))
* Improve ROMM access and configuration ([0c81a20](https://github.com/rigerc/home-assistant-addons/commit/0c81a206bc0e958983864da7e493b855abed5109))


### 🚀 Enhancements

* Centralize README generation with gomplate ([b7651da](https://github.com/rigerc/home-assistant-addons/commit/b7651da22f99f031439a9ce5450f711ba89cfdee))
* Improve Renovate config and Dockerfile practices ([002d2d5](https://github.com/rigerc/home-assistant-addons/commit/002d2d51532b66ae261e54e04b7e6bf45a7c9033))
* Standardize project URL extraction in build files ([3fd1b04](https://github.com/rigerc/home-assistant-addons/commit/3fd1b04a22cafe1b9daa173f1cfa094985f6ebd4))
* Update add-on versioning and build process ([2f715f5](https://github.com/rigerc/home-assistant-addons/commit/2f715f58632953ba952feb4dd05216547e362f74))


### 🧰 Maintenance

* update addon metadata [skip ci] ([18eaa08](https://github.com/rigerc/home-assistant-addons/commit/18eaa082871ac2bbf47b3306db2044fa929146f3))
* update addon metadata [skip ci] ([8d52386](https://github.com/rigerc/home-assistant-addons/commit/8d5238651c50d81a497cd0e0f0b42f4c58d74857))
* Update config and linting ([0bac62d](https://github.com/rigerc/home-assistant-addons/commit/0bac62dad01cc3b508c76b4490018efa24ed9a73))

## [Unreleased]

### Added

- Initial release of Romm add-on
- Support for external MariaDB database
- Metadata provider configuration (ScreenScraper, RetroAchievements, SteamGridDB, IGDB)
- Ingress support for web UI integration
- ROM library management from Home Assistant share folder
