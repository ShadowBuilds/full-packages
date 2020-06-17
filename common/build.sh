#!/usr/bin/env bash
set -euo pipefail

# If the script needs more than this, then switch to using _lib.sh
progname="$(basename "$0" .sh)"
warn() { printf >&2 '%s: %s\n' "$progname" "$*"; }
die() { warn "$@"; exit 1; }

pushd "$(dirname "$0")"
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

# Entirely optional variables:
# The Branch can also be a Tag (is just passed to git clone --branch)
: "${BUILD_BRANCH:+used to use other than remote head}"
: "${GIMME_GO_VERSION:+used to pre-install and use a different release of Go}"

# These should not need to be overridden
: "${BUILD_ROOT:=${TMPDIR:-/tmp}/nats-build/$$}"
: "${BUILD_RELDIR:=$(basename "${SERVER_REPO:?}")}"
: "${GIT_CMD:=git}"
: "${GO_CMD:=go}"

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

pushd "$rel"

if "$BUILD_WITH_GOMODULES"; then
  go mod download -x
else
  export GO111MODULE=off
fi

"$GO_CMD" build -v -o "$BUILD_ROOT/${BINARY_NAME:?}" "${BUILD_FILESPEC:?}"

popd
ls -l

popd
if [[ -n "${COPY_BINARIES_TO_DIR:-}" ]]; then
  mkdir -pv -- "$COPY_BINARIES_TO_DIR"
  cp -v "$BUILD_ROOT/$BINARY_NAME" "$COPY_BINARIES_TO_DIR/./"
fi
