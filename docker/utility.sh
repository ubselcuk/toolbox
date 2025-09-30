#!/usr/bin/env bash
. "$(dirname "$0")/../lib/common.sh"

require_root

check_docker() {
  info "Checking Docker installation and status..."
  if ! command -v docker &> /dev/null; then
    error "Docker command not found. Please install Docker first."
    exit 1
  else 
    info "Docker is installed."
  fi

  if ! docker info &> /dev/null; then
    error "Docker does not seem to be running. Please start Docker service."
    exit 1
  else 
    info "Docker service is running."
  fi
}

remove_container() {
    local CONTAINER_NAME=$1
    info "Removing Docker container: $CONTAINER_NAME"

    info "Checking if container '$CONTAINER_NAME' exists..."
    if docker ps -a --format '{{.Names}}' | grep -qw "$CONTAINER_NAME"; then
        info "Container '$CONTAINER_NAME' exists. Stopping and removing it..."
        docker stop "$CONTAINER_NAME" && docker rm "$CONTAINER_NAME"
        info "Container '$CONTAINER_NAME' stopped and removed."
    else
        info "Container '$CONTAINER_NAME' does not exist. No need to stop or remove."
    fi
}