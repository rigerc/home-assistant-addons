# bluemaex's Add-ons Shack

![Project Stage][project-stage-shield]
![Maintenance][maintenance-shield]
[![License][license-shield]](LICENSE.md)

## About

Home Assistant allows anyone to create add-on repositories to share their
add-ons for Home Assistant easily. This repository contains my personal,
but free to use [Home Assistant Add-ons][ha-addons].

[![Add Repository Link][add-repository-image]][add-repository-button]

## Usage

Adding this add-ons repository to your Home Assistant instance is pretty
straightforward. In the Home Assistant add-on store, a possibility to
add a repository is provided.

1. Navigate in your Home Assistant frontend to **Supervisor -> Add-on Store**
1. Add this new repository by URL (`https://github.com/rigerc/home-assistant-addons`)
1. Find the add-on that you want to use and click it
1. Click on the "INSTALL" button

## Add-ons

This repository contains the following add-ons:

### &#10003; [Cleanuparr][addon-cleanuparr]

![Latest Version][cleanuparr-version-shield]
![Supports armhf Architecture][cleanuparr-armhf-shield]
![Supports armv7 Architecture][cleanuparr-armv7-shield]
![Supports aarch64 Architecture][cleanuparr-aarch64-shield]
![Supports amd64 Architecture][cleanuparr-amd64-shield]

Automated cleanup for Sonarr, Radarr, Lidarr, Readarr, and Whisparr downloads. Remove stalled, slow, failed imports, and malware torrents.
[:books: Cleanuparr add-on documentation][addon-doc-cleanuparr]

### &#10003; [Profilarr][addon-profilarr]

![Latest Version][profilarr-version-shield]
![Supports armhf Architecture][profilarr-armhf-shield]
![Supports armv7 Architecture][profilarr-armv7-shield]
![Supports aarch64 Architecture][profilarr-aarch64-shield]
![Supports amd64 Architecture][profilarr-amd64-shield]

Profile management for *arr applications
[:books: Profilarr add-on documentation][addon-doc-profilarr]

### &#10003; [Romm][addon-romm]

![Latest Version][romm-version-shield]
![Supports armhf Architecture][romm-armhf-shield]
![Supports armv7 Architecture][romm-armv7-shield]
![Supports aarch64 Architecture][romm-aarch64-shield]
![Supports amd64 Architecture][romm-amd64-shield]

Self-hosted ROM collection manager and emulator launcher.
Scan, organize, and manage game collections across 400+ platforms with
automatic metadata fetching and in-browser gameplay.

[:books: Romm add-on documentation][addon-doc-romm]


## License

MIT License

Copyright (c) 2023 Max Stockner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

[add-repository-button]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/rigerc/home-assistant-addons
[ha-addons]: https://www.home-assistant.io/addons/
[add-repository-image]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[license-shield]: https://img.shields.io/github/license/rigerc/home-assistant-addons.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2025.svg
[project-stage-shield]: https://img.shields.io/badge/project%20stage-production%20ready-brightgreen.svg
[addon-cleanuparr]: https://github.com/rigerc/home-assistant-addons/tree/cleanuparr-0.1.1
[addon-doc-cleanuparr]: https://github.com/rigerc/home-assistant-addons/blob/cleanuparr-0.1.1/README.md
[cleanuparr-version-shield]: https://img.shields.io/badge/version-0.1.1-blue.svg
[cleanuparr-aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[cleanuparr-amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[cleanuparr-armhf-shield]: https://img.shields.io/badge/armhf-no-red.svg
[cleanuparr-armv7-shield]: https://img.shields.io/badge/armv7-no-red.svg
[addon-profilarr]: https://github.com/rigerc/home-assistant-addons/tree/profilarr-0.1.7
[addon-doc-profilarr]: https://github.com/rigerc/home-assistant-addons/blob/profilarr-0.1.7/README.md
[profilarr-version-shield]: https://img.shields.io/badge/version-0.1.7-blue.svg
[profilarr-aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[profilarr-amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[profilarr-armhf-shield]: https://img.shields.io/badge/armhf-no-red.svg
[profilarr-armv7-shield]: https://img.shields.io/badge/armv7-no-red.svg
[addon-romm]: https://github.com/rigerc/home-assistant-addons/tree/romm-0.1.26
[addon-doc-romm]: https://github.com/rigerc/home-assistant-addons/blob/romm-0.1.26/README.md
[romm-version-shield]: https://img.shields.io/badge/version-0.1.26-blue.svg
[romm-aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[romm-amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[romm-armhf-shield]: https://img.shields.io/badge/armhf-no-red.svg
[romm-armv7-shield]: https://img.shields.io/badge/armv7-no-red.svg
