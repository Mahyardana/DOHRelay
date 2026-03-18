# Multi-stage Dockerfile for DOHRelay
# Supports cross-platform builds for Windows, Linux, and macOS
# Build: docker build -t dohrelay:latest .
# Multi-arch: docker buildx build --platform linux/amd64,linux/arm64 -t dohrelay:latest .

# ============================================================================
# Build Stage
# ============================================================================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

# Copy project file
COPY ["DOHRelay/DOHRelay.csproj", "DOHRelay/"]

# Restore dependencies
RUN dotnet restore "DOHRelay/DOHRelay.csproj"

# Copy application source
COPY . .

# Build application
WORKDIR "/src/DOHRelay"
RUN dotnet build "DOHRelay.csproj" -c Release -o /app/build --no-restore

# ============================================================================
# Publish Stage
# ============================================================================
FROM build AS publish

RUN dotnet publish "DOHRelay.csproj" -c Release -o /app/publish --no-restore --no-build

# ============================================================================
# Runtime Stage
# ============================================================================
FROM mcr.microsoft.com/dotnet/runtime:8.0

WORKDIR /app

# Copy published application
COPY --from=publish /app/publish .

# Create non-root user for security
RUN addgroup --gid 1001 dohrelay && \
    useradd --uid 1001 --gid 1001 dohrelay && \
    chown -R dohrelay:dohrelay /app

USER dohrelay

# Expose port
EXPOSE 5000

# Set environment variables
ENV ASPNETCORE_URLS=http://0.0.0.0:5000
ENV ASPNETCORE_ENVIRONMENT=Production

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/healthz || exit 1

# Run application
ENTRYPOINT ["./DOHRelay"]
