#!/bin/sh
# Swaps the node binary of the upstream image for the one in /tmp/node-overlay,
# but only if that one is a newer patch/minor of the SAME major. If upstream
# already ships the same or a newer node, nothing changes, so the overlay
# retires itself once upstream catches up.
set -eu

OVERLAY=/tmp/node-overlay
cur_bin=$(command -v node)
cur=$("$cur_bin" -v)
new=$(LD_LIBRARY_PATH="$OVERLAY" "$OVERLAY/node" -v)

decision=$("$cur_bin" -e '
  const p = v => v.replace(/^v/, "").split(".").map(Number);
  const [a, b] = [p(process.argv[1]), p(process.argv[2])];
  if (a[0] !== b[0]) console.log("major");
  else if (b[1] > a[1] || (b[1] === a[1] && b[2] > a[2])) console.log("newer");
  else console.log("keep");
' "$cur" "$new")

case "$decision" in
  newer)
    if [ -f "$OVERLAY/libatomic.so.1" ] && [ ! -e /usr/lib/libatomic.so.1 ]; then
      cp "$OVERLAY/libatomic.so.1" /usr/lib/libatomic.so.1
    fi
    cp "$OVERLAY/node" "$cur_bin"
    [ "$(node -v)" = "$new" ] || { echo "node overlay failed: $(node -v) != $new" >&2; exit 1; }
    echo "upstream $cur -> $new" > /etc/node-overlay
    ;;
  major)
    echo "upstream $cur (overlay $new skipped: different major)" > /etc/node-overlay
    ;;
  *)
    echo "upstream $cur (overlay $new not newer)" > /etc/node-overlay
    ;;
esac
cat /etc/node-overlay
