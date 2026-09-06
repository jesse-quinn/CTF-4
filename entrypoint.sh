#!/bin/bash

set -e

# Start the outer Docker daemon and the outer sshd.
dockerd > /dev/null 2>&1 &
/usr/sbin/sshd -D > /dev/null 2>&1 &

# Wait for the outer Docker engine to come up before deploying the inner stack.
until docker info >/dev/null 2>&1; do sleep 1; done

# Run the CMD (docker compose builds the inner stack and pulls base images).
exec "$@"
