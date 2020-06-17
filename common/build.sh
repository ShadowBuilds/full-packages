#!/usr/bin/env bash
set -euo pipefail

# If the script needs more than this, then switch to using _lib.sh
progname="$(basename "$0" .sh)"
warn() { printf >&2 '%s: %s\n' "$progname" "$*"; }
die() { warn "$@"; exit 1; }

InvokerDir="$(/bin/pwd -P 2>/dev/null || pwd)"
pushd "$(dirname "$0")"
BuildConfigDir="$(/bin/pwd -P 2>/dev/null || pwd)"

# We enable goreleaser if the config file exists, but let vars.sh re-disable
# that if needed vars.sh can also mutate GORELEASER_ARGV[@]; our normal
# provide-defaults idiom doesn't work with non-scalars.
if [[ -f ./goreleaser.yml ]]; then
  USE_GORELEASER=true
  GORELEASER_ARGV=(--snapshot)
else
  USE_GORELEASER=false
  GORELEASER_ARGV=()
fi

if [[ -f ./vars.sh ]]; then
  . ./vars.sh
fi

# This absolutely must be set by now, probably from vars.sh
: "${SERVER_REPO:?}"

# Reasonable defaults which might need to be overridden
: "${BUILD_FILESPEC:=.}"
: "${BUILD_IN_GOPATH:=true}"
: "${REPO_GO_PARENT=github.com/nats-io}"
: "${BINARY_NAME:=$(basename "${SERVER_REPO:?}")}"
: "${BUILD_WITH_GOMODULES:=false}"
: "${GORELEASER_ARGS:=--snapshot}"
: "${SHALLOW_SINCE:=2 days ago}"

# Entirely optional variables:
# The Branch can also be a Tag (is just passed to git clone --branch)
: "${BUILD_BRANCH:+used to use other than remote head}"
: "${GIMME_GO_VERSION:+used to pre-install and use a different release of Go}"
: "${REPO_REFERENCE:+path to a reference repo to reduce network copying}"

# These should not need to be overridden
: "${BUILD_ROOT:=${TMPDIR:-/tmp}/nats-build/$$}"
: "${BUILD_RELDIR:=$(basename "${SERVER_REPO:?}")}"
: "${GIT_CMD:=git}"
: "${GO_CMD:=go}"
if [[ -n "${NEED_USER:-}" ]]; then
  : "${NEED_SCRIPTS:=true}"
  : "${SCRIPTS_DIR:=../common/scripts}"
else
  : "${NEED_SCRIPTS:=false}"
fi

# -----------------------------8< cut here >8-----------------------------

if [[ -d "$BUILD_ROOT" ]]; then die "BUILD_ROOT($BUILD_ROOT) must not already exist"; fi

mkdir -pv -- "$BUILD_ROOT" || die "mkdir($BUILD_ROOT) failed $?"
cleanup() { rm -fr -- "$BUILD_ROOT"; }
trap cleanup EXIT

cd "$BUILD_ROOT"

if [[ -n "${GIMME_GO_VERSION:-}" ]]; then
  export GIMME_GO_VERSION
  eval "$(gimme)"
fi

clone_args=(--depth 1 --single-branch)
if [[ -n "${BUILD_BRANCH:-}" ]]; then
  clone_args+=(--branch "$BUILD_BRANCH")
fi
if [[ -n "${REPO_REFERENCE:-}" ]]; then
  clone_args+=(--reference "$REPO_REFERENCE")
fi
clone_args+=( "${SERVER_REPO:?}" )

if "$BUILD_IN_GOPATH"; then
  rel="go/src"
  if [[ -n "$REPO_GO_PARENT" ]]; then
    rel="${rel}/$REPO_GO_PARENT"
  fi
  rel="${rel}/${BUILD_RELDIR:?}"
  mkdir -pv -- "$rel"
  export GOPATH="$BUILD_ROOT/go${GOPATH:+:}${GOPATH:-}"
else
  rel="./${BUILD_RELDIR:?}"
fi
clone_args+=( "$rel" )

"$GIT_CMD" clone "${clone_args[@]}"
"$GIT_CMD" -C "$rel" fetch --tags  # I haven't found a sane way to restrict this to recent tags
"$GIT_CMD" -C "$rel" fetch --shallow-since "$SHALLOW_SINCE"

if "$USE_GORELEASER"; then
  # pkg is already in the gitignore, so we don't make the repo dirty by putting
  # extra files in there, and for goreleaser we need all the files in there.
  pushd "$BuildConfigDir"
  mkdir -pv "$BUILD_ROOT/$rel/pkg"

  if [[ -d default ]]; then
    mkdir -pv "$BUILD_ROOT/$rel/pkg/default"
    cp -pRv -- default/* "$BUILD_ROOT/$rel/pkg/default/./"
  fi

  pwd
  svcs=(*.service) || true
  if [[ ${#svcs[@]} -gt 0 ]]; then
    mkdir -pv "$BUILD_ROOT/$rel/pkg/svc"
    cp -pv -- "${svcs[@]}" "$BUILD_ROOT/$rel/pkg/svc/./"
    oIFS="$IFS"
    IFS=':'
    export INSTALLER_INSTALL_SYSTEMD="${svcs[*]}"
    IFS="$oIFS"
  fi

  cp -v goreleaser.yml "$BUILD_ROOT/$rel/pkg/goreleaser.yml"

  if "$NEED_SCRIPTS"; then
    mkdir -pv "$BUILD_ROOT/$rel/pkg/scripts"
    if [[ -n "$NEED_USER" ]]; then
      export INSTALLER_RUNTIME_USER="$NEED_USER"
    fi
    for X in "${SCRIPTS_DIR:?}"/*; do
      Y="$BUILD_ROOT/$rel/pkg/scripts/$(basename "$X")"
      printf >&2 '+ subst %s -> %s\n' "$X" "$Y"
      envsubst '$INSTALLER_RUNTIME_USER $INSTALLER_INSTALL_SYSTEMD' < "$X" > "$Y"
      chmod 755 "$Y"
    done
  fi

  popd
fi

pushd "$rel"

if "$USE_GORELEASER"; then
  goreleaser "${GORELEASER_ARGV[@]}" --config pkg/goreleaser.yml
else
  if "$BUILD_WITH_GOMODULES"; then
    go mod download -x
  else
    export GO111MODULE=off
  fi

  "$GO_CMD" build -v -o "$BUILD_ROOT/${BINARY_NAME:?}" "${BUILD_FILESPEC:?}"
fi

popd
ls -l

popd
if [[ -n "${COPY_BINARIES_TO_DIR:-}" ]]; then
  mkdir -pv -- "$COPY_BINARIES_TO_DIR"
  if "$USE_GORELEASER"; then
    cp -vpR "$BUILD_ROOT/$rel/dist/" "$COPY_BINARIES_TO_DIR/"
  else
    cp -v "$BUILD_ROOT/$BINARY_NAME" "$COPY_BINARIES_TO_DIR/./"
  fi
fi
