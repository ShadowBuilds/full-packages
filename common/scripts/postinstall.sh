#!/bin/sh -eu

# The build script for setting up the packaging layout uses envsubst(1) to
# selectively replace environment variables in this file.
# If this comment is in sync with reality, then only these variables will be
# replaced:
#   INSTALLER_RUNTIME_USER
#   INSTALLER_INSTALL_SYSTEMD

adduser --quiet --system --group "${INSTALLER_RUNTIME_USER}"

if [ -n "$INSTALLER_INSTALL_SYSTEMD" ]; then
  oIFS="$IFS"
  IFS=':'
  set $INSTALLER_INSTALL_SYSTEMD
  IFS="$oIFS"
  for svc; do
    fullpath="/lib/systemd/system/$svc"
    systemctl enable "$fullpath"
  done
  for svc; do
    systemctl start "$svc"
  done
fi
