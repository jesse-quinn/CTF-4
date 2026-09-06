#!/bin/sh
# Start sshd as root, then run the Flask app as the unprivileged jinja user so
# that command execution through the template injection lands as jinja.
set -e

service ssh start

exec su jinja -c "python3 /app/app.py"
