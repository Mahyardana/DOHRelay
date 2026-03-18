# Multi-stage Dockerfile for DOHRelay
# Supports cross-platform builds for Windows, Linux, and macOS
# Build: docker build -t dohrelay:latest .
# Multi-arch: docker buildx build --platform linux/amd64,linux/arm64 -t dohrelay:latest .

# BUILDPLATFORM = platform of the build host (always native, no QEMU for SDK)
# TARGETPLATFORM = destination platform for the runtime image
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETARCH

# ============================================================================
# Build Stage — always runs on the host platform to avoid QEMU segfaults
# ============================================================================
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS build

ARG TARGETARCH

WORKDIR /src

# Copy project file
COPY ["DOHRelay/DOHRelay.csproj", "DOHRelay/"]

# Restore for the target RID
RUN case "$TARGETARCH" in \
        amd64) RID=linux-x64 ;; \
        arm64) RID=linux-arm64 ;; \
        *) echo "Unsupported TARGETARCH: $TARGETARCH" && exit 1 ;; \
    esac && \
    dotnet restore "DOHRelay/DOHRelay.csproj" -r $RID

# Copy application source
COPY . .

# Publish for the target RID (cross-compiled on native host, no emulation needed)
WORKDIR "/src/DOHRelay"
RUN case "$TARGETARCH" in \
        amd64) RID=linux-x64 ;; \
        arm64) RID=linux-arm64 ;; \
        *) echo "Unsupported TARGETARCH: $TARGETARCH" && exit 1 ;; \
    esac && \
    dotnet publish "DOHRelay.csproj" -c Release -r $RID --self-contained -o /app/publish

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
