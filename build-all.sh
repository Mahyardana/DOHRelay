#!/bin/bash

# DOHRelay Multi-Platform Build Script (Bash/Linux/macOS)
# Builds DOHRelay for multiple architectures and creates archives

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

Platform="${1:-all}"
SELF_CONTAINED="${SELF_CONTAINED:-true}"

echo -e "${GREEN}DOHRelay Multi-Platform Build Script${NC}"

# Current OS
OS_TYPE="$(uname -s)"

# Define platforms to build
declare -a PLATFORMS=()
declare -a PLATFORM_NAMES=()

if [ "$Platform" = "all" ]; then
    PLATFORMS=("linux-x64" "linux-arm64" "linux-arm" "osx-x64" "osx-arm64")
    PLATFORM_NAMES=("Linux x86-64" "Linux ARM64" "Linux ARM" "macOS x86-64" "macOS ARM64")
    
    # Only include macOS builds on macOS
    if [ "$OS_TYPE" = "Darwin" ]; then
        PLATFORMS=("osx-x64" "osx-arm64")
        PLATFORM_NAMES=("macOS x86-64" "macOS ARM64")
    fi
    
    # Only include Windows builds on Windows (cannot cross-compile)
    if [ "$OS_TYPE" = "MINGW64_NT" ] || [ "$OS_TYPE" = "CYGWIN_NT" ]; then
        PLATFORMS=("win-x64" "win-x86" "win-arm64")
        PLATFORM_NAMES=("Windows x86-64" "Windows x86" "Windows ARM64")
    fi
else
    PLATFORMS=("$Platform")
    PLATFORM_NAMES=("$Platform")
fi

# Create output directory
mkdir -p artifacts

SUCCESS_COUNT=0
FAIL_COUNT=0

# Build for each platform
for i in "${!PLATFORMS[@]}"; do
    RID="${PLATFORMS[$i]}"
    NAME="${PLATFORM_NAMES[$i]}"
    
    echo -e "\n${YELLOW}Building for $NAME ($RID)...${NC}"
    
    # Restore dependencies
    echo "  Restoring dependencies..."
    if ! dotnet restore DOHRelay/DOHRelay.csproj > /dev/null 2>&1; then
        echo -e "  ${RED}✗ Restore failed for $RID${NC}"
        ((FAIL_COUNT++))
        continue
    fi
    
    # Publish
    echo "  Publishing..."
    PUBLISH_CMD="dotnet publish DOHRelay/DOHRelay.csproj -c Release -r $RID --no-restore"
    
    if [ "$SELF_CONTAINED" = "true" ]; then
        PUBLISH_CMD="$PUBLISH_CMD --self-contained"
    fi
    
    PUBLISH_CMD="$PUBLISH_CMD -o ./publish_$RID"
    
    if eval "$PUBLISH_CMD" > /dev/null 2>&1; then
        # Create archive
        echo "  Creating archive..."
        ARCHIVE_NAME="DOHRelay-$RID"
        
        cd publish_$RID
        tar czf "../artifacts/$ARCHIVE_NAME.tar.gz" .
        cd ..
        
        echo -e "  ${GREEN}✓ Created: artifacts/$ARCHIVE_NAME.tar.gz${NC}"
        
        # Cleanup
        rm -rf "publish_$RID"
        
        ((SUCCESS_COUNT++))
    else
        echo -e "  ${RED}✗ Build failed for $RID${NC}"
        ((FAIL_COUNT++))
    fi
done

# Summary
echo ""
echo -e "${YELLOW}$(printf '=%.0s' {1..50})${NC}"
echo -e "${GREEN}Build Summary${NC}"
echo -e "  ${GREEN}Successful: $SUCCESS_COUNT${NC}"
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "  ${GREEN}Failed: $FAIL_COUNT${NC}"
else
    echo -e "  ${RED}Failed: $FAIL_COUNT${NC}"
fi
echo -e "  ${GREEN}Output directory: artifacts${NC}"
echo -e "${YELLOW}$(printf '=%.0s' {1..50})${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "\n${GREEN}✓ All builds completed successfully!${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some builds failed!${NC}"
    exit 1
fi
