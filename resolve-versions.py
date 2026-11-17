#!/usr/bin/env python3
"""Pick the upstream versions to build.

stdin: upstream tags, one per line (anything that is not X.Y.Z is ignored).
env:   LATEST  upstream's current stable version (X.Y.Z); newer tags such as
               betas/next are ignored.
       WINDOW  how many minor lines to keep patched (default 3).
       ONLY    build just this version (manual run).

Prints a JSON list of {"version", "minor", "latest"}: the highest patch of the
newest WINDOW minor lines up to LATEST. Patch releases of an older minor line
are therefore still built, so a host pinned to e.g. :2.47 keeps getting fixes.
"""
import json
import os
import re
import sys


def key(v):
    return tuple(int(x) for x in v.split("."))


latest = os.environ["LATEST"].lstrip("v")
only = os.environ.get("ONLY", "").lstrip("v")
window = int(os.environ.get("WINDOW", "3"))

if only:
    if not re.fullmatch(r"\d+\.\d+\.\d+", only):
        sys.exit(f"Unexpected version: {only}")
    print(json.dumps([{"version": only, "minor": only.rsplit(".", 1)[0], "latest": only == latest}]))
    sys.exit(0)

if not re.fullmatch(r"\d+\.\d+\.\d+", latest):
    sys.exit(f"Unexpected latest version: {latest}")

tags = {t.strip().lstrip("v") for t in sys.stdin}
tags = {t for t in tags if re.fullmatch(r"\d+\.\d+\.\d+", t) and key(t) <= key(latest)}
tags.add(latest)

best = {}
for t in tags:
    minor = t.rsplit(".", 1)[0]
    if minor not in best or key(t) > key(best[minor]):
        best[minor] = t

minors = sorted(best, key=key, reverse=True)[:window]
print(json.dumps([{"version": best[m], "minor": m, "latest": best[m] == latest} for m in minors]))
