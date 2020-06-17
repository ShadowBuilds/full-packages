#!/bin/sh -eu

# The build script for setting up the packaging layout uses envsubst(1) to
# selectively replace environment variables in this file.
# If this comment is in sync with reality, then only these variables will be
# replaced:
#   INSTALLER_RUNTIME_USER -- but in accordance with debian policy we don't remove users
#   INSTALLER_INSTALL_SYSTEMD

# Be careful to make sure that we continue past failures to stop, so that we
# also disable (ie, remove the /etc/systemd symlinks even if the user has
# stopped the service manually)

if [ -n "$INSTALLER_INSTALL_SYSTEMD" ]; then
  oIFS="$IFS"
  IFS=':'
  set $INSTALLER_INSTALL_SYSTEMD
  IFS="$oIFS"
  for svc; do
    systemctl stop "$svc" || echo "stop($svc) failed $?"
  done
  for svc; do
    fullpath="/lib/systemd/system/$svc"
    systemctl disable "$fullpath" || echo "disable($svc) failed $?"
  done
fi
