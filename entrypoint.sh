#!/usr/bin/env bash

# Initialize environment
source "$IDF_PATH/export.sh"
source "$HOME/.cargo/env"

# Execute argument passed to `docker run`.  If it's a shell (/bin/bash) will
# remain in the container
exec "$@"