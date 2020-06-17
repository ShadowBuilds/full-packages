#!/bin/sh -eu

# The build script for setting up the packaging layout uses envsubst(1) to
# selectively replace environment variables in this file.
# If this comment is in sync with reality, then only these variables will be
# replaced:
#   INSTALLER_RUNTIME_USER

adduser --quiet --system --group "${INSTALLER_RUNTIME_USER}"
