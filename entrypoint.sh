#!/bin/sh

# Use this as the entrypoint for the image so a non-root user can own the
# work directory even though the container must start as root to use S6.
chown -R ${CT_USER}:${CT_GID} ${HOME}/work
exec "$@"