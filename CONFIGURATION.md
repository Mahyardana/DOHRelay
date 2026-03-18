# Configuration Guide

This document explains how to configure DOHRelay for different environments and deployment scenarios.

## Table of Contents

1. [Basic Configuration](#basic-configuration)
2. [Network Settings](#network-settings)
3. [HTTPS/TLS Configuration](#httpstls-configuration)
4. [Logging Configuration](#logging-configuration)
5. [Environment-Specific Settings](#environment-specific-settings)
6. [Windows Service Deployment](#windows-service-deployment)
7. [Linux Systemd Service Deployment](#linux-systemd-service-deployment)
8. [Docker Deployment](#docker-deployment)
9. [Reverse Proxy Configuration](#reverse-proxy-configuration)

## Basic Configuration

### appsettings.json

The main configuration file controls application behavior:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

**Key Settings**:
- **Logging.LogLevel.Default**: Sets default log level (Trace, Debug, Information, Warning, Error, Critical)
- **AllowedHosts**: Comma-separated list of hostnames the application responds to (use "*" to allow all)

## Network Settings

### Listening Address and Port

Edit `Properties/launchSettings.json` to change the listening address:

```json
{
  "profiles": {
    "https": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "launchUrl": "weatherforecast",
      "applicationUrl": "https://localhost:5000;http://localhost:5001",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
```

**Alternative**: Use environment variables:

```bash
# Windows PowerShell
$env:ASPNETCORE_URLS = "http://0.0.0.0:5000"

# Linux/macOS
export ASPNETCORE_URLS="http://0.0.0.0:5000"
```

Or command-line arguments:

```bash
dotnet run --urls "http://0.0.0.0:5000"
```

### Binding to Multiple Ports

```bash
dotnet run --urls "http://0.0.0.0:5000;https://0.0.0.0:5001"
```

## HTTPS/TLS Configuration

### Generate Self-Signed Certificate (Development)

```bash
# Windows
dotnet dev-certs https

# Linux/macOS
dotnet dev-certs https --trust
```

### Use Custom Certificate (Production)

1. **Create PFX certificate** (if you only have .pem/.crt files):
   ```bash
   openssl pkcs12 -export -in certificate.crt -inkey private.key -out certificate.pfx
   ```

2. **Configure in Program.cs**:
   ```csharp
   var builder = WebApplicationBuilder.CreateBuilder(args);
   
   builder.WebHost.ConfigureKestrel(serverOptions =>
   {
       serverOptions.ConfigureHttpsDefaults(httpsOptions =>
       {
           httpsOptions.ServerCertificate = new X509Certificate2(
               "/path/to/certificate.pfx", 
               "password"
           );
       });
   });
   ```

3. **Or configure via HTTPS_CERTIFICATE environment variable**:
   ```bash
   export ASPNETCORE_Kestrel__Certificates__Default__Path=/path/to/certificate.pfx
   export ASPNETCORE_Kestrel__Certificates__Default__Password=your_password
   ```

## Logging Configuration

### Log Levels

Configure logging in `appsettings.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "DOHRelay.Controllers": "Debug"
    }
  }
}
```

**Levels** (most verbose to least):
- `Trace` - Very detailed diagnostic information
- `Debug` - Debugging information
- `Information` - General informational messages
- `Warning` - Warning messages for potential issues
- `Error` - Error messages for failures
- `Critical` - Critical failures requiring immediate attention
- `None` - No logging

### Production Logging

`appsettings.Production.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Error"
    }
  },
  "AllowedHosts": "yourdomain.com"
}
```

## Environment-Specific Settings

### Development Environment

`appsettings.Development.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Information"
    }
  },
  "AllowedHosts": "*"
}
```

To run with development settings:

```bash
dotnet run
# or explicitly
set ASPNETCORE_ENVIRONMENT=Development
dotnet run
```

### Production Environment

`appsettings.Production.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning"
    }
  },
  "AllowedHosts": "yourdomain.com"
}
```

To run with production settings:

```bash
set ASPNETCORE_ENVIRONMENT=Production
dotnet run
```

## Windows Service Deployment

### Install as Windows Service

1. **Publish the application**:
   ```bash
   dotnet publish -c Release -r win-x64 --self-contained
   ```

2. **Install using NSSM (NonSumoIni service manager)**:
   
   Download NSSM from: https://nssm.cc/download
   
   ```bash
   nssm install DOHRelayService "C:\path\to\DOHRelay.exe"
   nssm set DOHRelayService AppEnvironmentExtra ASPNETCORE_URLS=http://0.0.0.0:5000
   nssm set DOHRelayService AppEnvironmentExtra ASPNETCORE_ENVIRONMENT=Production
   nssm start DOHRelayService
   ```

3. **Verify service is running**:
   ```bash
   nssm status DOHRelayService
   ```

4. **Remove service**:
   ```bash
   nssm stop DOHRelayService
   nssm remove DOHRelayService confirm
   ```

### Using SC.exe (Built-in)

```bash
# Create service
sc create DOHRelayService binPath= "C:\path\to\DOHRelay.exe" start= auto

# Start service
net start DOHRelayService

# Stop service
net stop DOHRelayService

# Delete service
sc delete DOHRelayService
```

## Linux Systemd Service Deployment

### Create Systemd Service File

Create `/etc/systemd/system/dohrelay.service`:

```ini
[Unit]
Description=DOHRelay DNS-over-HTTPS Service
After=network.target

[Service]
Type=notify
User=dohrelay
WorkingDirectory=/opt/dohrelay
ExecStart=/opt/dohrelay/DOHRelay
Environment="ASPNETCORE_ENVIRONMENT=Production"
Environment="ASPNETCORE_URLS=http://0.0.0.0:5000"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Setup Service

```bash
# Create user for service
sudo useradd -r -s /bin/false dohrelay

# Copy published files
sudo mkdir -p /opt/dohrelay
sudo cp -r bin/Release/net8.0/linux-x64/publish/* /opt/dohrelay/

# Set permissions
sudo chown -R dohrelay:dohrelay /opt/dohrelay
sudo chmod +x /opt/dohrelay/DOHRelay

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable dohrelay
sudo systemctl start dohrelay

# Check status
sudo systemctl status dohrelay
```

### Service Management

```bash
# View logs
sudo journalctl -u dohrelay -f

# Stop service
sudo systemctl stop dohrelay

# Restart service
sudo systemctl restart dohrelay
```

## Docker Deployment

### Dockerfile

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 5000
ENV ASPNETCORE_URLS=http://0.0.0.0:5000
ENTRYPOINT ["./DOHRelay"]
```

### Build and Run Docker Image

```bash
# Build image
docker build -t dohrelay:latest .

# Run container
docker run -d \
  --name dohrelay \
  -p 5000:5000 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  dohrelay:latest

# View logs
docker logs -f dohrelay

# Stop container
docker stop dohrelay
```

### Docker Compose

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  dohrelay:
    build: .
    container_name: dohrelay
    ports:
      - "5000:5000"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ASPNETCORE_URLS=http://0.0.0.0:5000
    restart: unless-stopped
    networks:
      - dohrelay-network

networks:
  dohrelay-network:
    driver: bridge
```

Run with Docker Compose:

```bash
docker-compose up -d
```

## Reverse Proxy Configuration

### Nginx

```nginx
upstream dohrelay {
    server localhost:5000;
}

server {
    listen 80;
    server_name doh.example.com;

    location / {
        proxy_pass http://dohrelay;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### IIS (Windows)

1. **Install Application Request Routing (ARR)**
2. **Create new website** pointing to your published DOHRelay folder
3. **Configure ARR rule**:
   - New Outbound Rule
   - Match URL path: `.*`
   - Rewrite URL: `http://localhost:5000/{R:0}`

### Apache

```apache
<VirtualHost *:80>
    ServerName doh.example.com
    
    ProxyPreserveHost On
    ProxyPass / http://localhost:5000/
    ProxyPassReverse / http://localhost:5000/
    
    RequestHeader set X-Forwarded-Proto http
    RequestHeader set X-Forwarded-Port 80
</VirtualHost>
```

## Performance Tuning

### Connection Pool Settings

Add to `Program.cs`:

```csharp
var httpClientHandler = new HttpClientHandler
{
    MaxConnectionsPerServer = 10,
    AutomaticDecompression = System.Net.DecompressionMethods.GZip | System.Net.DecompressionMethods.Deflate
};

var httpClient = new HttpClient(httpClientHandler)
{
    Timeout = TimeSpan.FromSeconds(30)
};
```

### Kestrel Tuning

```csharp
builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = 512;
    options.Limits.RequestHeadersTimeout = TimeSpan.FromSeconds(30);
});
```

## Troubleshooting

### Port Already in Use

```bash
# Windows - Find process using port
netstat -ano | findstr :5000

# Linux - Find process using port
sudo lsof -i :5000
```

### Permission Denied (Linux)

```bash
# Verify file permissions
ls -la /opt/dohrelay/

# Fix permissions
sudo chmod +x /opt/dohrelay/DOHRelay
```

### Certificate Not Trusted

- Use Let's Encrypt for free certificates: https://letsencrypt.org/
- Configure via your reverse proxy (nginx, IIS)
- Or install certificate in system certificate store

### Service Won't Start

1. Check logs (Windows Event Viewer or `journalctl`)
2. Verify environment variables are set correctly
3. Ensure port is not in use and accessible
4. Check file permissions and ownership

## Security Checklist

- [ ] HTTPS/TLS enabled for production
- [ ] Firewall rules configured to restrict access
- [ ] Running on non-root user (Linux)
- [ ] Regular backups of configuration
- [ ] Log rotation configured
- [ ] Rate limiting implemented (via reverse proxy)
- [ ] Network isolation from public internet if needed
