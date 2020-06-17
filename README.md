full-packages
=============

At time of writing the nats-io packages for nats-server and friends include
just the binaries.  We want to explore providing more full-featured packages
such that administrators can install them and expect things to Just Work.

Ultimately any building done in this repository is likely to move into the
per-codebase repositories.  Working here lets us iterate quickly without
risking breaking existing build processes.

## Building

There are sub-directories for various projects.  Each has a `build.sh`.
Invoke that to build.

Optionally, specify a path in `$COPY_BINARIES_TO_DIR` in environ and the built
binaries will be copied to that directory (will be made).

This build process is designed for tagged releases, so a shallow clone will
normally be sufficient; we extend it to `$SHALLOW_SINCE` to aid in recent
rebuilds; this defaults to `2 days ago`; if doing builds long after a tag has
been laid down, then `export SHALLOW_SINCE='35 days ago'` is a useful pattern.

<!-- FIXME: also $COPY_PACKAGES_TO_DIR ?  Where do those go by default? -->
