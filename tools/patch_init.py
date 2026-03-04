#!/usr/bin/env python3
"""
Patch opensshd.init to redirect sshd logs to a file.

Original: $SSHD  (no log output)
Patched:  $SSHD -E /data/adb/ssh/sshd.log
          + mkdir -p /data/adb/ssh at start of start_service()
"""
import os
import re
import sys

LOG_FILE = "/data/adb/ssh/sshd.log"
CANDIDATES = ["common/opensshd.init", "opensshd.init"]

patched_any = False
for path in CANDIDATES:
    if not os.path.isfile(path):
        continue

    text = open(path).read()
    original = text

    # 1. Add -E LOG_FILE to bare $SSHD invocations (skip already patched lines)
    text = re.sub(
        r"(\$SSHD)(?!\s+-E)(\s*$)",
        r"\1 -E " + LOG_FILE + r"\2",
        text,
        flags=re.MULTILINE,
    )

    # 2. Ensure log directory exists before sshd starts
    text = text.replace(
        "start_service() {",
        "start_service() {\n    mkdir -p $(dirname " + LOG_FILE + ")",
        1,  # only replace first occurrence
    )

    if text == original:
        print(f"[patch_init] No changes needed in: {path}")
        continue

    open(path, "w").write(text)
    patched_any = True
    print(f"[patch_init] Patched: {path}")
    for i, line in enumerate(text.splitlines(), 1):
        if "SSHD" in line or "mkdir" in line:
            print(f"  {i:3d}: {line.rstrip()}")

if not patched_any:
    print("[patch_init] Warning: no opensshd.init file found in expected locations")
    sys.exit(1)
