# Quick Start Guide

Get DOHRelay up and running in minutes!

## Prerequisites

- **.NET 8.0 SDK** ([Download](https://dotnet.microsoft.com/download/dotnet/8.0))
- **Windows**, **Linux**, or **macOS**

## Option 1: Run Locally (Development)

```bash
# Clone the repository
git clone <your-repo-url>
cd DOHRelay

# Restore dependencies
dotnet restore

# Run the application
dotnet run

# The service will be available at:
# http://192.168.88.246:5000 (or your configured address)
```

## Option 2: Docker (Recommended for Deployment)

```bash
# Build and run with Docker Compose
docker-compose up -d

# Check if it's running
docker-compose ps

# View logs
docker-compose logs -f dohrelay

# Stop services
docker-compose down
```

## Option 3: Build for Multiple Platforms

### Windows (PowerShell)
```powershell
# Build all platforms
.\build-all.ps1

# Or specific platform
.\build-all.ps1 -Platform linux-x64

# Artifacts will be in ./artifacts/
```

### Linux/macOS (Bash)
```bash
# Make script executable
chmod +x build-all.sh

# Build all platforms
./build-all.sh

# Or specific platform
./build-all.sh linux-x64

# Artifacts will be in ./artifacts/
```

## Configuration

### Default Settings
- **URL**: `http://0.0.0.0:5000`
- **Environment**: `Development`
- **Logging**: `Information`

### Change Settings
Edit `appsettings.json` to modify:
- Listening address
- Port
- Logging levels
- Environment-specific settings

See [CONFIGURATION.md](./CONFIGURATION.md) for detailed options.

## Deployment

### Windows Service
```powershell
# Publish for Windows
dotnet publish -c Release -r win-x64 --self-contained

# See DEPLOYMENT.md for service installation steps
```

### Linux Systemd Service
```bash
# Publish for Linux
dotnet publish -c Release -r linux-x64 --self-contained

# See DEPLOYMENT.md for systemd setup
```

### Docker / Kubernetes
```bash
# Build Docker image
docker build -t dohrelay:latest .

# Run container
docker run -p 5000:5000 dohrelay:latest

# Or: docker-compose up -d
```

## Test the Service

### Using curl
```bash
# Test the health endpoint
curl http://localhost:5000/healthz

# The weatherforecast endpoint (sample)
curl http://localhost:5000/weatherforecast
```

## Directory Structure

```
DOHRelay/
├── Controllers/          # API endpoints
├── Properties/           # Launch configurations
├── appsettings.json      # Main configuration
├── Program.cs            # Application startup
├── Dockerfile            # Docker build configuration
├── docker-compose.yml    # Docker Compose configuration
├── build-all.ps1         # Windows build script
├── build-all.sh          # Linux/macOS build script
├── README.md             # Full documentation
├── CONFIGURATION.md      # Configuration guide
└── DEPLOYMENT.md         # Deployment instructions
```

## Common Tasks

### Change Listening Port
Edit `Properties/launchSettings.json` or run:
```bash
dotnet run --urls "http://0.0.0.0:8080"
```

### Enable HTTPS
See [CONFIGURATION.md](./CONFIGURATION.md#httpstls-configuration)

### View Application Logs
```bash
# For systemd service
sudo journalctl -u dohrelay -f

# For Docker
docker-compose logs -f dohrelay
```

### Monitor Service Health
```bash
# Health check endpoint (if configured)
curl http://localhost:5000/healthz
```

## Troubleshooting

### Port Already in Use
```bash
# Windows
netstat -ano | findstr :5000

# Linux
sudo lsof -i :5000
```

### .NET Runtime Not Found
```bash
# Install .NET 8.0
# Windows: https://dotnet.microsoft.com/download/dotnet/8.0#windows
# Linux: https://dotnet.microsoft.com/download/dotnet/8.0#linux
# macOS: https://dotnet.microsoft.com/download/dotnet/8.0#macos
```

### Connection Refused
1. Verify the service is running: `docker-compose ps`
2. Check the configured URL in settings
3. Verify firewall allows the port
4. Check logs for errors

## Next Steps

1. **Review Documentation**
   - [README.md](./README.md) - Overview and features
   - [CONFIGURATION.md](./CONFIGURATION.md) - Configuration options
   - [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment procedures

2. **Deploy to Production**
   - Choose deployment method (systemd, Windows Service, Docker, etc.)
   - Follow [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed steps
   - Configure HTTPS/TLS certificates

3. **Monitor and Maintain**
   - Set up log aggregation
   - Configure health checks
   - Plan backup and disaster recovery

## Getting Help

- Check [CONFIGURATION.md](./CONFIGURATION.md) for setup issues
- Review [DEPLOYMENT.md](./DEPLOYMENT.md) for deployment problems
- Open an issue on GitHub for bugs or feature requests

## Support

For questions or issues:
- 📖 Read the [README.md](./README.md)
- ⚙️ Check [CONFIGURATION.md](./CONFIGURATION.md)
- 🚀 Review [DEPLOYMENT.md](./DEPLOYMENT.md)
- 🐛 [Report issues](https://github.com/yourusername/DOHRelay/issues)
