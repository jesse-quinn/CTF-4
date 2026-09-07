#!/bin/sh
# Start sshd first, then run the Flask app as the unprivileged jinja user so that
# command execution through the template injection lands as jinja.
#
# sshd is started defensively and is deliberately NOT coupled to the web entry
# point: the Flask app is the primary service, so a sshd hiccup must not prevent
# it from serving. No `set -e` here for the same reason.

mkdir -p /run/sshd
service ssh start || /usr/sbin/sshd || echo "warning: sshd failed to start; continuing to serve the web app" >&2

exec su jinja -c "python3 /app/app.py"
