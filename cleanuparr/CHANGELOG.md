# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-01-27

### Added
- Ingress support for seamless Home Assistant integration (+2 security points)
- Comprehensive configuration options with full schema validation
- HTTP certificate validation settings (enabled/disabled/local addresses)
- Search delay configuration to prevent overwhelming indexers
- Advanced logging configuration with archive support
- Log rolling size, retained count, and time limit options
- Log archive configuration with retention policies
- AppArmor profile for enhanced security (+1 security point)
- Comprehensive documentation (README.md, DOCS.md)
- Dry run mode enabled by default for safe testing
- Support banner display option

### Changed
- Migrated from direct port access to Ingress (recommended)
- Updated Cleanuparr binary version to 2.5.1
- Improved initialization script with configuration generation
- Enhanced AppArmor profile with specific path rules
- Updated base images to Home Assistant base 3.20 (Alpine)
- Reorganized add-on options with logical grouping
- Improved logging with structured levels
- Better error handling in service scripts

### Fixed
- Fixed syntax error in service run script (missing quote)
- Fixed permission handling for configuration directory
- Improved pre-start checks with better error messages

### Deprecated
- Direct port access (still available but Ingress is recommended)
- Legacy configuration format (migrated to new schema)

### Security
- Added comprehensive AppArmor profile
- Enabled Ingress for secure web UI access
- Restrict file access to specific directories
- Deny access to sensitive system paths

## [0.1.3] - 2024-01-20

### Added
- Initial release of Cleanuparr add-on
- Support for amd64, aarch64, and armv7 architectures
- Basic configuration options (log_level only)
- Direct port access on 11011
- AppArmor profile for basic security
- Simple S6-overlay service configuration

### Known Issues
- No Ingress support (use direct port access)
- Limited configuration options
- Basic AppArmor profile
- Minimal documentation

## [Unreleased]

### Planned
- S6-RC v3 service definitions (modern format)
- Translation support for multiple languages
- Service discovery for automatic *arr detection
- Custom notification providers in add-on options
- Health check improvements
- Metrics endpoint for monitoring
- Backup/restore integration
- Webhook support for external integrations

[0.2.0]: https://github.com/your-username/ha-addons/compare/v0.1.3...v0.2.0
[0.1.3]: https://github.com/your-username/ha-addons/releases/tag/v0.1.3
