# riger's Home Assistant Add-ons

[![Project Stage](https://img.shields.io/badge/project%20stage-production%20ready-brightgreen.svg)](https://github.com/rigerc/home-assistant-addons)
[![Maintenance](https://img.shields.io/maintenance/yes/2025.svg)](https://github.com/rigerc/home-assistant-addons)
[![License](https://img.shields.io/github/license/rigerc/home-assistant-addons.svg)](LICENSE.md)

## About

A collection of community add-ons for [Home Assistant](https://www.home-assistant.io/addons/), designed to extend your smart home with self-hosted tools for media management, automation, and gaming. These add-ons wrap popular Docker containers into Home Assistant's Supervisor format with proper configuration, ingress support, and multi-architecture compatibility.

**Why use these add-ons?** Each add-on is configured specifically for Home Assistant's environment with sensible defaults, automatic updates from upstream projects, and seamless integration with the Supervisor's monitoring and logging systems.

## Installation

### Adding the Repository

1. Navigate to **Settings** → **Add-ons** → **Add-on Store** in your Home Assistant frontend
2. Click the three-dot menu in the top-right corner
3. Select **Add-on store** (or "Add repository")
4. Enter this URL: `https://github.com/rigerc/home-assistant-addons`
5. Click **Add**

### Installing an Add-on

1. Browse the **Add-on Store** and find the add-on you want
2. Click the add-on to view details
3. Click the **INSTALL** button
4. Configure the add-on using the **Configuration** tab
5. Start the add-on from the **Info** tab

## Add-ons

### [Cleanuparr](./cleanuparr/README.md)

[![Version](https://img.shields.io/badge/version-0.2.13-blue)](https://github.com/rigerc/home-assistant-addons/tree/cleanuparr-0.2.13)
[![aarch64](https://img.shields.io/badge/aarch64-yes-green)](https://github.com/rigerc/home-assistant-addons)
[![amd64](https://img.shields.io/badge/amd64-yes-green)](https://github.com/rigerc/home-assistant-addons)
[![Upstream](https://img.shields.io/badge/upstream-2.5.1-informational)](https://github.com/cleanuparr/cleanuparr)
[![Outdated](https://img.shields.io/badge/outdated-no-success)](https://github.com/rigerc/home-assistant-addons)

Automated cleanup tool for Sonarr, Radarr, and download clients. Removes unwanted or blocked files, manages stalled downloads, and enforces blacklists/whitelists. Includes malware detection and automatic search triggers for removed content.

**Key features:**
- Automatic removal of blocked and unwanted releases
- Stalled download detection and cleanup
- Malware scanning capabilities
- Configurable blacklist/whitelist rules

### [Profilarr](./profilarr/README.md)

[![Version](https://img.shields.io/badge/version-0.1.13-blue)](https://github.com/rigerc/home-assistant-addons/tree/profilarr-0.1.13)
[![aarch64](https://img.shields.io/badge/aarch64-yes-green)](https://github.com/rigerc/home-assistant-addons)
[![amd64](https://img.shields.io/badge/amd64-yes-green)](https://github.com/rigerc/home-assistant-addons)
[![Upstream](https://img.shields.io/badge/upstream-v1.1.3-informational)](https://github.com/santiagosayshey/profilarr)
[![Outdated](https://img.shields.io/badge/outdated-yes-critical)](https://github.com/rigerc/home-assistant-addons)

Centralized profile management for *arr applications (Sonarr, Radarr, Lidarr, etc.). Synchronize quality profiles, language profiles, and custom formats across your media management stack.

### [Profilarr v1](./profilarr-v1/README.md)

[![Version](https://img.shields.io/badge/version-0.1.12-blue)](https://github.com/rigerc/home-assistant-addons/tree/profilarr-v1-0.1.12)
[![aarch64](https://img.shields.io/badge/aarch64-yes-green)](https://github.com/rigerc/home-assistant-addons)
[![amd64](https://img.shields.io/badge/amd64-yes-green)](https://github.com/rigerc/home-assistant-addons)
[![Upstream](https://img.shields.io/badge/upstream-v1.1.3-informational)](https://github.com/santiagosayshey/profilarr)
[![Outdated](https://img.shields.io/badge/outdated-no-success)](https://github.com/rigerc/home-assistant-addons)

Legacy version of Profilarr for users who need the v1 interface.

### [Romm](./romm/README.md)

[![Version](https://img.shields.io/badge/version-1.0-blue)](https://github.com/rigerc/home-assistant-addons/tree/romm-1.0)
[![aarch64](https://img.shields.io/badge/aarch64-yes-green)](https://github.com/rigerc/home-assistant-addons)
[![amd64](https://img.shields.io/badge/amd64-yes-green)](https://github.com/rigerc/home-assistant-addons)
[![Upstream](https://img.shields.io/badge/upstream-4.6.0-informational)](https://github.com/rommapp/romm)
[![Outdated](https://img.shields.io/badge/outdated-no-success)](https://github.com/rigerc/home-assistant-addons)

Self-hosted ROM collection manager and emulator launcher. Scan, organize, and manage game collections across 400+ platforms with automatic metadata fetching and in-browser gameplay.

**Key features:**
- Support for 400+ gaming platforms
- Automatic metadata scraping from multiple sources
- In-browser gameplay via web emulators
- Beautiful, responsive UI for browsing your collection

## Supported Architectures

All add-ons in this repository support the following architectures:

| Architecture | Status |
|--------------|--------|
| **aarch64** (ARM 64-bit) | ✅ Supported |
| **amd64** (x86-64) | ✅ Supported |
| armv7 | ❌ Not supported |
| armhf | ❌ Not supported |

## Troubleshooting

### Add-on won't start

1. Check the **Log** tab in the add-on panel for error messages
2. Verify your configuration in the **Configuration** tab
3. Ensure your Home Assistant has sufficient resources
4. Try restarting the add-on or your entire Home Assistant

### Upstream updates

Add-ons are built to track the latest releases from their upstream projects. When a new version is released:

1. The add-on will be updated automatically (check the **Version** in the Info tab)
2. You can manually update by clicking **UPDATE** if available
3. Configuration changes between versions are noted in individual add-on documentation

## Contributing

Found a bug or have a feature request? Please [open an issue](https://github.com/rigerc/home-assistant-addons/issues) or submit a pull request.

### Development

To build or modify add-ons locally, refer to the [Home Assistant Add-on Development documentation](https://developers.home-assistant.io/docs/add-ons/).

## License

This repository is licensed under the MIT License. See the [`LICENSE`](LICENSE.md) file for details.

Individual add-ons may include software under different licenses - refer to specific add-on documentation for more information.

---

[Add Repository](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/rigerc/home-assistant-addons) · [Report Issue](https://github.com/rigerc/home-assistant-addons/issues)
