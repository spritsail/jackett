#!/bin/sh
set -e

export CFG_DIR="${CFG_DIR:-/config}"

if ! su-exec -e touch "$CFG_DIR/.write-test"; then
    2>&1 echo "Warning: No permission to write in '$CFG_DIR' directory."
    2>&1 echo "         Correcting permissions to prevent a crash"
    2>&1 echo
    chown $SUID:$SGID "$CFG_DIR"
    chmod o+rw "$CFG_DIR"
fi
# Remove temporary file
rm -f touch "$CFG_DIR/.write-test"

exec su-exec -e "$@"
