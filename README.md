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

If you have a local clone of the git repo already on disk, then exporting
`$REPO_REFERENCE` to point to that repository will result in a reference
clone, speeding up the git cloning and reducing network transfer volume.

<!-- FIXME: also $COPY_PACKAGES_TO_DIR ?  Where do those go by default? -->

## Using

The nats-server should be installed and running by default.

Two example tuning configs are installed, for administrators to as a
(possibly complete) starting-point.

To enable JetStream:

```sh
sudo mv /etc/default/nats-server.d/jetstream.disabled /etc/default/nats-server.d/jetstream.conf
sudo systemctl restart nats-server
```

To use a config file `/etc/nats-server.conf` which you must create:

```sh
sudo mv /etc/default/nats-server.d/configfile.disabled /etc/default/nats-server.d/configfile.conf
sudo systemctl restart nats-server
```

Note that both of those disabled files stomp on the `$OPTIONS` variable, so do
not enable both.  You can use your own defaults file, working from those as a
baseline, or you can just use a config file and enable jetstream inside that
config file.
