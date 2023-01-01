#!/bin/bash

# Constants -- change these to match your setup
DOMAIN="jamon.dev"
# The below are probably accurate if you have a default Ubuntu DigitalOcean droplet.
# If you edit them, also update any references in qb64-watcher.service!
SSH_USER="root"
REMOTE_ROOT="/root"
REMOTE_REPO_FOLDER="$REMOTE_ROOT/repo"
REMOTE_QB64_FOLDER="$REMOTE_ROOT/qb64"
REMOTE_BUILD_FOLDER="$REMOTE_ROOT/build"
