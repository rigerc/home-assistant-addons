---
name: curl
description: Use for expert guidance on curl HTTP requests, API testing, file transfers, shell automation, and network debugging
version: 1.0.0
author: claude-code-development
category: bash-scripting
keywords: [curl, http, api, requests, web, networking, bash, shell, scripting, automation, testing, debugging]
triggers: ["curl", "http request", "api testing", "file download", "web scraping", "network troubleshooting"]
license: MIT
---

# Curl Mastery Skill

**Provides expert guidance on curl command-line tool and libcurl library usage**

## Quick Start
```bash
# Basic GET request
curl https://api.example.com/data

# POST JSON data
curl -X POST -H "Content-Type: application/json" \
     -d '{"name":"John"}' https://api.example.com/users

# Download file with resume
curl -C - -o file.zip https://example.com/file.zip
```

## When to Use
- Building/testing HTTP clients and APIs
- File transfers (FTP, SFTP, HTTP downloads/uploads)
- Web scraping and automation
- Network debugging and troubleshooting
- Shell script automation with web services

## Expert Guidance
- **Command construction**: Proper syntax, options, and parameter handling
- **Authentication**: Basic, Bearer tokens, OAuth, client certificates
- **Data handling**: JSON, form data, file uploads, streaming
- **Error handling**: Timeouts, retries, response code validation
- **Performance**: Parallel operations, compression, connection reuse
- **Security**: SSL verification, certificate management, secure practices

## Available References
- [command-examples.md](references/command-examples.md) - Comprehensive command patterns
- [authentication.md](references/authentication.md) - All authentication methods
- [automation.md](references/automation.md) - Shell script integration
- [troubleshooting.md](references/troubleshooting.md) - Common issues and solutions
- [performance.md](references/performance.md) - Optimization techniques
- [security.md](references/security.md) - Secure usage patterns

## Tools Integration
- Works with Bash scripting, shell automation
- Integrates with JSON processing tools (jq)
- Supports API testing workflows
- Compatible with CI/CD pipelines

## Related Skills
- [jq](../jq/) - JSON processing for curl responses
- [fish-shell](../fish-shell/) - Interactive curl command testing
- [bats-tester](../bats-tester/) - Testing curl-based scripts