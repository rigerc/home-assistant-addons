# Curl Mastery Skill

Expert guidance on curl command-line tool and libcurl library usage for HTTP requests, API testing, file transfers, shell automation, and network debugging.

## Overview

This skill provides comprehensive knowledge and practical examples for using curl effectively in various scenarios including API development, file transfers, shell scripting, and network troubleshooting.

## Features

- **HTTP Requests**: GET, POST, PUT, DELETE with headers and authentication
- **File Operations**: Uploads, downloads, resume interrupted transfers
- **API Testing**: JSON handling, authentication, response validation
- **Performance**: Parallel downloads, timeouts, retry logic
- **Security**: SSL/TLS, certificates, authentication methods
- **Automation**: Shell script integration and CI/CD pipelines

## Structure

```
curl/
├── SKILL.md                 # Main skill documentation (Level 2)
├── README.md               # This file
├── references/             # Detailed documentation (Level 3)
│   ├── command-examples.md # Comprehensive command patterns
│   ├── authentication.md   # All authentication methods
│   ├── automation.md       # Shell script integration
│   ├── troubleshooting.md  # Common issues and solutions
│   ├── performance.md      # Optimization techniques
│   └── security.md         # Secure usage patterns
├── scripts/
│   └── template.sh         # Secure curl script template
└── assets/
    └── curl-format.txt     # Timing analysis format
```

## Quick Start

```bash
# Basic GET request
curl https://api.example.com/data

# POST JSON data
curl -X POST -H "Content-Type: application/json" \
     -d '{"name":"John"}' https://api.example.com/users

# Download file with resume
curl -C - -o file.zip https://example.com/file.zip

# Debug with verbose output
curl -v -H "Authorization: Bearer $TOKEN" https://api.example.com/protected
```

## Usage

This skill is automatically activated when you use curl-related commands or ask questions about:

- HTTP requests and API testing
- File downloads and uploads
- Web scraping and automation
- Network debugging and troubleshooting
- Shell script integration with web services

## Integration

Works seamlessly with other bash-scripting skills:
- **[jq](../jq/)**: JSON processing for curl responses
- **[fish-shell](../fish-shell/)**: Interactive curl command testing
- **[bats-tester](../bats-tester/)**: Testing curl-based scripts

## Security

The skill includes comprehensive security best practices:
- SSL/TLS certificate validation
- Secure authentication methods
- Input validation and sanitization
- Protection against common vulnerabilities

## Performance

Optimization techniques for:
- Connection reuse and pooling
- Parallel operations
- Bandwidth management
- Timeout and retry strategies

## Contributing

This skill follows progressive disclosure principles with three levels:
1. **Level 1**: Minimal metadata (always loaded)
2. **Level 2**: Core skill content (loaded when triggered)
3. **Level 3**: Detailed references (loaded as needed)

## License

MIT License - see skill metadata for details.