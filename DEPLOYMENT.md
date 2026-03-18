# Deployment Guide

Complete guide to deploying DOHRelay to Windows and Linux environments with multi-architecture support.

## Table of Contents

1. [Build for Multiple Architectures](#build-for-multiple-architectures)
2. [Windows Deployment](#windows-deployment)
3. [Linux Deployment](#linux-deployment)
4. [macOS Deployment](#macos-deployment)
5. [Docker Deployment](#docker-deployment)
6. [Release Management](#release-management)

## Build for Multiple Architectures

### Supported Runtime Identifiers (RID)

| Platform | Architecture | RID | Command |
|----------|--------------|-----|---------|
| Windows | x64 | `win-x64` | `dotnet publish -c Release -r win-x64` |
| Windows | x86 | `win-x86` | `dotnet publish -c Release -r win-x86` |
| Windows | ARM64 | `win-arm64` | `dotnet publish -c Release -r win-arm64` |
| Linux | x64 | `linux-x64` | `dotnet publish -c Release -r linux-x64` |
| Linux | ARM/ARM64 | `linux-arm`, `linux-arm64` | `dotnet publish -c Release -r linux-arm64` |
| macOS | x64 (Intel) | `osx-x64` | `dotnet publish -c Release -r osx-x64` |
| macOS | ARM64 (Apple Silicon) | `osx-arm64` | `dotnet publish -c Release -r osx-arm64` |

### Self-Contained Builds

Self-contained builds include the .NET runtime, making them larger but requiring no runtime installation:

```bash
# Windows x64 - Self-contained
dotnet publish -c Release -r win-x64 --self-contained
# Output: bin/Release/net8.0/win-x64/publish/

# Linux x64 - Self-contained
dotnet publish -c Release -r linux-x64 --self-contained
# Output: bin/Release/net8.0/linux-x64/publish/

# Linux ARM64 - Self-contained (e.g., for Raspberry Pi)
dotnet publish -c Release -r linux-arm64 --self-contained
# Output: bin/Release/net8.0/linux-arm64/publish/
```

### Framework-Dependent Builds

Smaller builds that require .NET 8.0 runtime on the target system:

```bash
# Framework-dependent for current platform
dotnet publish -c Release

# Output: bin/Release/net8.0/publish/
```

### Batch Build for Multiple Platforms

Create `build-all.ps1` (PowerShell):

```powershell
$platforms = @("win-x64", "win-x86", "linux-x64", "linux-arm64", "osx-x64", "osx-arm64")

foreach ($rid in $platforms) {
    Write-Host "Building for $rid..." -ForegroundColor Green
    dotnet publish -c Release -r $rid --self-contained
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $rid build successful" -ForegroundColor Green
    } else {
        Write-Host "✗ $rid build failed" -ForegroundColor Red
    }
}

Write-Host "All builds complete!" -ForegroundColor Green
```

Run with:
```bash
powershell -ExecutionPolicy Bypass -File build-all.ps1
```

Or create `build-all.sh` (Bash):

```bash
#!/bin/bash

platforms=("win-x64" "linux-x64" "linux-arm64" "osx-x64" "osx-arm64")

for rid in "${platforms[@]}"
do
    echo "Building for $rid..."
    dotnet publish -c Release -r $rid --self-contained
    if [ $? -eq 0 ]; then
        echo "✓ $rid build successful"
    else
        echo "✗ $rid build failed"
        exit 1
    fi
done

echo "All builds complete!"
```

Run with:
```bash
chmod +x build-all.sh
./build-all.sh
```

## Windows Deployment

### Option 1: Standalone Executable

1. **Build for Windows**:
   ```bash
   dotnet publish -c Release -r win-x64 --self-contained --no-restore
   ```

2. **Access published files**:
   ```
   bin/Release/net8.0/win-x64/publish/DOHRelay.exe
   ```

3. **Run directly**:
   ```bash
   cd bin/Release/net8.0/win-x64/publish
   .\DOHRelay.exe
   ```

4. **Create batch file** (`start-dohrelay.bat`):
   ```batch
   @echo off
   set ASPNETCORE_URLS=http://0.0.0.0:5000
   set ASPNETCORE_ENVIRONMENT=Production
   .\DOHRelay.exe
   pause
   ```

### Option 2: Windows Service (NSSM)

**Download NSSM**: https://nssm.cc/download

1. **Extract NSSM** to a folder (e.g., `C:\nssm\`)

2. **Install service** (as Administrator):
   ```powershell
   # Set variables
   $publishPath = "C:\path\to\bin\Release\net8.0\win-x64\publish"
   $exePath = "$publishPath\DOHRelay.exe"
   
   # Run installer
   C:\nssm\nssm install DOHRelayService $exePath
   ```

3. **Configure service environment**:
   ```powershell
   C:\nssm\nssm set DOHRelayService AppDirectory $publishPath
   C:\nssm\nssm set DOHRelayService AppEnvironmentExtra ASPNETCORE_URLS=http://0.0.0.0:5000
   C:\nssm\nssm set DOHRelayService AppEnvironmentExtra ASPNETCORE_ENVIRONMENT=Production
   C:\nssm\nssm set DOHRelayService Start SERVICE_AUTO_START
   ```

4. **Start service**:
   ```powershell
   C:\nssm\nssm start DOHRelayService
   ```

5. **Check logs**:
   ```powershell
   # NSSM creates log file
   type "$publishPath\..\..\..\..\..\nssm.log"
   ```

6. **Uninstall service**:
   ```powershell
   C:\nssm\nssm stop DOHRelayService
   C:\nssm\nssm remove DOHRelayService confirm
   ```

### Option 3: Windows Service (SC.exe - Built-in)

```powershell
# Variables
$exePath = "C:\path\to\publish\DOHRelay.exe"
$displayName = "DOH Relay Service"

# Create service
New-Service -Name DOHRelayService `
    -BinaryPathName $exePath `
    -DisplayName $displayName `
    -StartupType Automatic `
    -Description "DNS-over-HTTPS relay service"

# Start service
Start-Service -Name DOHRelayService

# Check status
Get-Service -Name DOHRelayService

# Stop service
Stop-Service -Name DOHRelayService

# Remove service
Remove-Service -Name DOHRelayService
```

## Linux Deployment

### Option 1: Standalone Binary

1. **Build for Linux**:
   ```bash
   dotnet publish -c Release -r linux-x64 --self-contained --no-restore
   ```

2. **Transfer files**:
   ```bash
   scp -r bin/Release/net8.0/linux-x64/publish/ user@server:/opt/dohrelay/
   ```

3. **Make executable**:
   ```bash
   chmod +x /opt/dohrelay/DOHRelay
   ```

4. **Run**:
   ```bash
   /opt/dohrelay/DOHRelay
   ```

### Option 2: Systemd Service (Recommended)

1. **Publish application**:
   ```bash
   dotnet publish -c Release -r linux-x64 --self-contained
   ```

2. **Setup directory and permissions**:
   ```bash
   sudo mkdir -p /opt/dohrelay
   sudo cp -r bin/Release/net8.0/linux-x64/publish/* /opt/dohrelay/
   
   sudo useradd -r -s /bin/false dohrelay || true
   sudo chown -R dohrelay:dohrelay /opt/dohrelay
   sudo chmod +x /opt/dohrelay/DOHRelay
   ```

3. **Create systemd service file** (`/etc/systemd/system/dohrelay.service`):
   ```ini
   [Unit]
   Description=DOHRelay DNS-over-HTTPS Service
   Documentation=https://github.com/yourusername/DOHRelay
   After=network.target
   
   [Service]
   Type=simple
   User=dohrelay
   WorkingDirectory=/opt/dohrelay
   ExecStart=/opt/dohrelay/DOHRelay
   
   # Environment
   Environment="ASPNETCORE_ENVIRONMENT=Production"
   Environment="ASPNETCORE_URLS=http://0.0.0.0:5000"
   
   # Restart behavior
   Restart=on-failure
   RestartSec=10
   
   # Security settings
   NoNewPrivileges=true
   ProtectSystem=strict
   ProtectHome=yes
   PrivateTmp=yes
   
   [Install]
   WantedBy=multi-user.target
   ```

4. **Enable and start service**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable dohrelay
   sudo systemctl start dohrelay
   ```

5. **Verify service**:
   ```bash
   sudo systemctl status dohrelay
   sudo journalctl -u dohrelay -n 50
   sudo journalctl -u dohrelay -f  # Follow logs
   ```

### Option 3: Supervisor (Alternative Process Manager)

Install supervisor:
```bash
sudo apt-get install supervisor  # Debian/Ubuntu
sudo yum install supervisor       # RHEL/CentOS
```

Create `/etc/supervisor/conf.d/dohrelay.conf`:
```ini
[program:dohrelay]
command=/opt/dohrelay/DOHRelay
directory=/opt/dohrelay
user=dohrelay
autostart=true
autorestart=true
environment=ASPNETCORE_ENVIRONMENT=Production,ASPNETCORE_URLS=http://0.0.0.0:5000
stdout_logfile=/var/log/dohrelay/stdout.log
stderr_logfile=/var/log/dohrelay/stderr.log
```

Start service:
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start dohrelay
```

## macOS Deployment

### Option 1: Direct Execution

```bash
dotnet publish -c Release -r osx-x64 --self-contained
./bin/Release/net8.0/osx-x64/publish/DOHRelay
```

### Option 2: Launchd Service

Create `~/Library/LaunchAgents/com.example.dohrelay.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.dohrelay</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/dohrelay/DOHRelay</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>/opt/dohrelay</string>
    <key>StandardErrorPath</key>
    <string>/tmp/dohrelay.err</string>
    <key>StandardOutPath</key>
    <string>/tmp/dohrelay.out</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>ASPNETCORE_ENVIRONMENT</key>
        <string>Production</string>
        <key>ASPNETCORE_URLS</key>
        <string>http://127.0.0.1:5000</string>
    </dict>
</dict>
</plist>
```

Load service:
```bash
launchctl load ~/Library/LaunchAgents/com.example.dohrelay.plist
```

## Docker Deployment

### Multi-Architecture Docker Build

Create `Dockerfile`:

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["DOHRelay.csproj", "./"]
RUN dotnet restore "DOHRelay.csproj"

COPY . .
RUN dotnet build "DOHRelay.csproj" -c Release -o /app/build

RUN dotnet publish "DOHRelay.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 5000
ENV ASPNETCORE_URLS=http://0.0.0.0:5000
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["./DOHRelay"]
```

### Build for Multiple Platforms

Using Docker Buildx (requires Docker 20.10+):

```bash
# Enable buildx
docker buildx create --use

# Build for multiple architectures
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t yourdockerhub/dohrelay:latest \
  --push .

# Or build locally without push
docker buildx build \
  --platform linux/amd64 \
  -t dohrelay:latest \
  .
```

### Docker Compose Multi-Service

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  dohrelay:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: dohrelay
    ports:
      - "5000:5000"
    environment:
      ASPNETCORE_ENVIRONMENT: Production
      ASPNETCORE_URLS: http://0.0.0.0:5000
    restart: unless-stopped
    networks:
      - dohrelay-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 5s

  nginx:
    image: nginx:latest
    container_name: dohrelay-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on:
      - dohrelay
    networks:
      - dohrelay-network

networks:
  dohrelay-network:
    driver: bridge
```

## Release Management

### Automated GitHub Release Workflow

See `.github/workflows/release.yml` for automated multi-platform builds and releases.

### Manual Release Process

1. **Tag release**:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. **Build all platforms**:
   ```bash
   ./build-all.ps1  # Windows
   # or
   ./build-all.sh   # Linux/macOS
   ```

3. **Create release artifacts**:
   ```bash
   # Create archive for each platform
   cd bin/Release/net8.0
   
   # Windows
   7z a DOHRelay-win-x64.7z win-x64/publish/
   
   # Linux x64
   tar czf DOHRelay-linux-x64.tar.gz linux-x64/publish/
   
   # Linux ARM64
   tar czf DOHRelay-linux-arm64.tar.gz linux-arm64/publish/
   ```

4. **Create GitHub release** with artifacts:
   - Go to Releases
   - Create new release
   - Upload compiled archives
   - Add release notes

## Rollback Procedure

### Windows Service

```powershell
# Stop current version
Stop-Service -Name DOHRelayService

# Restore previous version
Copy-Item -Path "C:\backups\DOHRelay-v1.0.0\*" -Destination "C:\dohrelay\" -Recurse -Force

# Start service
Start-Service -Name DOHRelayService
```

### Linux Systemd

```bash
# Stop service
sudo systemctl stop dohrelay

# Restore previous version
sudo cp -r /backups/DOHRelay-v1.0.0/* /opt/dohrelay/

# Start service
sudo systemctl start dohrelay
```

## Monitoring and Health Checks

### Add Health Check Endpoint

Add to `Program.cs`:

```csharp
app.MapHealthChecks("/healthz");
```

### Monitor Service Logs

```bash
# Windows Event Viewer
eventvwr

# Linux journalctl
sudo journalctl -u dohrelay -f

# Docker logs
docker logs -f dohrelay
```

### Uptime Monitoring

Use tools like:
- UptimeRobot (free)
- Pingdom
- Datadog
- New Relic

Configure to monitor: `http://your-domain/healthz`
