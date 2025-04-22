#!/bin/bash
#
# OpenXPKI Docker SELinux and Podman Compatibility Setup
# -----------------------------------------------------
# This script prepares the environment for running OpenXPKI containers
# on systems with SELinux enabled and/or using rootless Podman.
#

# Print colored output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Set defaults
USE_PODMAN=${USE_PODMAN:-0}
VERBOSE=${VERBOSE:-0}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --podman)
      USE_PODMAN=1
      shift
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --podman       Enable Podman compatibility mode"
      echo "  --verbose      Show more detailed output"
      echo "  --help         Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

log() {
  local level=$1
  local msg=$2
  local color=$NC
  
  if [ "$level" = "INFO" ]; then
    color=$GREEN
  elif [ "$level" = "WARN" ]; then
    color=$YELLOW
  elif [ "$level" = "ERROR" ]; then
    color=$RED
  fi
  
  echo -e "${color}[$level] $msg${NC}"
}

# Check if we're on a system with SELinux
if command -v getenforce &> /dev/null; then
  SELINUX_STATUS=$(getenforce)
  if [ "$SELINUX_STATUS" != "Disabled" ] && [ "$SELINUX_STATUS" != "Permissive" ]; then
    log "INFO" "SELinux is enabled (status: $SELINUX_STATUS)"
    SELINUX_ENABLED=1
  else
    log "INFO" "SELinux is not strictly enforcing (status: $SELINUX_STATUS)"
    SELINUX_ENABLED=0
  fi
else
  log "INFO" "SELinux not detected on this system"
  SELINUX_ENABLED=0
fi

# Set SELinux context on directories if needed
if [ "$SELINUX_ENABLED" = "1" ]; then
  log "INFO" "Setting SELinux context for OpenXPKI directories..."
  
  # Main configuration directory
  if [ -d "./openxpki-config" ]; then
    log "INFO" "Setting context for ./openxpki-config"
    chcon -Rt container_file_t ./openxpki-config || {
      log "WARN" "Could not set SELinux context on ./openxpki-config (permissions issue?)"
    }
  else
    log "WARN" "Configuration directory ./openxpki-config not found"
  fi
  
  # Additional directories can be added here
  # if [ -d "./another-dir" ]; then
  #   log "INFO" "Setting context for ./another-dir"
  #   chcon -Rt container_file_t ./another-dir
  # fi
  
  log "INFO" "SELinux contexts set"
fi

# Handle Podman compatibility
if [ "$USE_PODMAN" = "1" ]; then
  log "INFO" "Configuring for rootless Podman compatibility..."
  
  # Generate a docker-compose override file for Podman
  cat > ./docker-compose.podman.yml <<EOF
version: "3"
services:
  db:
    security_opt: 
      - label=disable
  openxpki-server:
    security_opt: 
      - label=disable
  openxpki-client:
    security_opt: 
      - label=disable
EOF
  
  log "INFO" "Created docker-compose.podman.yml"
  log "INFO" "To start with Podman compatibility, use:"
  log "INFO" "  docker-compose -f docker-compose.yml -f docker-compose.podman.yml up"
fi

# Final instructions
if [ "$SELINUX_ENABLED" = "1" ] || [ "$USE_PODMAN" = "1" ]; then
  log "INFO" "Setup complete. Your environment is now prepared for OpenXPKI."
  
  if [ "$USE_PODMAN" = "1" ]; then
    echo ""
    log "INFO" "For rootless Podman, use this command to start containers:"
    echo "  podman-compose -f docker-compose.yml -f docker-compose.podman.yml up"
    echo ""
  fi
else
  log "INFO" "No special configuration needed for your environment."
fi

exit 0
