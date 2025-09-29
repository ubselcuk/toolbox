#!/usr/bin/env bash
. "$(dirname "$0")/../lib/common.sh"

info "Cleaning up unused Docker resources..."

docker container prune -f
docker image prune -af
docker volume prune -f
docker network prune -f

info "Docker cleanup completed."