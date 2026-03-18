# DOHRelay

A lightweight **DNS-over-HTTPS (DoH) relay service** built with ASP.NET Core 8.0 that proxies DNS queries to Cloudflare's 1.1.1.1 resolver.

## Overview

DOHRelay acts as an intermediary service that accepts DNS-over-HTTPS requests and forwards them to Cloudflare's DNS service, returning the responses to clients. This enables you to run your own DoH proxy for privacy-focused DNS resolution.

### Features

- ✅ **DNS-over-HTTPS Support** - GET and POST request handling for DNS queries
- ✅ **Cloudflare Relay** - Forwards queries to Cloudflare's 1.1.1.1 DNS service
- ✅ **Cross-Platform** - Runs on Windows, Linux, and macOS
- ✅ **Multi-Architecture** - Supports x86, x64, ARM, and ARM64
- ✅ **HTTPS Ready** - Configured for secure communication
- ✅ **.NET 8.0** - Modern, high-performance ASP.NET Core framework

## Quick Start

### Prerequisites

- **.NET 8.0 SDK** ([Download here](https://dotnet.microsoft.com/download/dotnet/8.0))
- **Windows**, **Linux**, or **macOS**

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/DOHRelay.git
   cd DOHRelay
   ```

2. **Restore dependencies**
   ```bash
   dotnet restore
   ```

3. **Build the project**
   ```bash
   dotnet build
   ```

4. **Run the application**
   ```bash
   dotnet run
   ```

   The service will start on `http://192.168.88.246:5247` (default configuration)

### Configuration

See [CONFIGURATION.md](./CONFIGURATION.md) for detailed setup instructions including:
- Changing the listening address and port
- HTTPS configuration
- Logging levels
- Development vs. Production settings

## API Endpoints

### DNS Query (GET)
```
GET /dns-query?dns=<dns-query-bytes>
Content-Type: application/dns-message
```

### DNS Query (POST)
```
POST /dns-query
Content-Type: application/dns-message
Body: <dns-query-bytes>
```

**Response**: Returns DNS response in `application/dns-message` format

### Example (using curl)

```bash
# Using nslookup to generate query, then send via localhost DoH relay
nslookup example.com
```

## Building for Deployment

### Self-Contained Releases

Build for specific platforms:

```bash
# Windows x64
dotnet publish -c Release -r win-x64 --self-contained

# Linux x64
dotnet publish -c Release -r linux-x64 --self-contained

# Linux ARM64
dotnet publish -c Release -r linux-arm64 --self-contained

# macOS x64
dotnet publish -c Release -r osx-x64 --self-contained
```

Published files will be in `bin/Release/net8.0/<rid>/publish/`

### Framework-Dependent Deployment

```bash
dotnet publish -c Release
```

This creates a smaller deployment that requires .NET 8.0 runtime to be installed on the target system.

## Deployment

### Windows Service

To run DOHRelay as a Windows service, see [DEPLOYMENT.md](./DEPLOYMENT.md)

### Linux Systemd Service

To run DOHRelay as a systemd service, see [DEPLOYMENT.md](./DEPLOYMENT.md)

### Docker

```dockerfile
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app
COPY bin/Release/net8.0/linux-x64/publish ./
ENTRYPOINT ["./DOHRelay"]
```

## Project Structure

```
DOHRelay/
├── Controllers/
│   ├── DOHController.cs          # DNS-over-HTTPS relay logic
│   └── WeatherForecastController.cs  # Sample endpoint
├── Properties/
│   └── launchSettings.json       # Launch configurations
├── appsettings.json              # Default settings
├── appsettings.Development.json  # Development-specific settings
├── Program.cs                    # Application startup
└── DOHRelay.csproj              # Project configuration
```

## Configuration Files

- **appsettings.json** - Global application settings
- **appsettings.Development.json** - Development environment overrides
- **launchSettings.json** - Debug and launch profiles

## Requirements

- **Runtime**: .NET 8.0
- **Framework Dependencies**: Built-in ASP.NET Core libraries only
- **Memory**: Minimal (typical usage < 50MB)
- **CPU**: Single core sufficient for low-to-medium traffic

## Performance

- Lightweight relay with minimal overhead
- Single-threaded HTTP request handling
- Direct passthrough to Cloudflare DoH endpoint
- Typical response time: <100ms (depends on network latency to Cloudflare)

## Logging

Logging is configured in `appsettings.json`:
- **Default Level**: Information
- **AspNetCore Level**: Warning (to reduce noise)

Adjust logging levels in `appsettings.json` or environment-specific files.

## Security Considerations

⚠️ **HTTPS Configuration**: 
- Configure HTTPS/TLS certificates for production use
- See [CONFIGURATION.md](./CONFIGURATION.md) for certificate setup

⚠️ **Access Control**:
- Consider adding authentication/authorization for restricted access
- Use firewall rules to limit who can query the relay

⚠️ **Network**:
- Run behind a reverse proxy (nginx, IIS) for production
- Implement rate limiting to prevent abuse

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or suggestions, please open an [GitHub Issue](https://github.com/yourusername/DOHRelay/issues).

## References

- [RFC 8484 - DNS Queries over HTTPS (DoH)](https://tools.ietf.org/html/rfc8484)
- [Cloudflare 1.1.1.1 DNS](https://one.one.one.one/)
- [ASP.NET Core Documentation](https://docs.microsoft.com/aspnet/core)
- [.NET Runtime Identifiers](https://docs.microsoft.com/dotnet/core/rid-catalog)
