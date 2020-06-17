: "${SERVER_REPO:=https://github.com/nats-io/jetstream}"
: "${BINARY_NAME:=nats}"
: "${BUILD_FILESPEC=./nats/...}"

: "${GIMME_GO_VERSION=1.14.x}"
: "${BUILD_IN_GOPATH:=false}"
: "${BUILD_WITH_GOMODULES:=true}"
