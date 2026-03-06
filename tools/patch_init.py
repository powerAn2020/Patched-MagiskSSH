#!/usr/bin/env python3
"""
Patch opensshd.init to use explicit config and redirect sshd logs to a file.

Original: $SSHD  (no log output, no config)
Patched:  $SSHD -f /data/adb/ssh/sshd_config -E /data/adb/ssh/sshd.log
          + mkdir -p /data/adb/ssh at start of start_service()

The script walks the current directory tree to find opensshd.init,
since the GitLab source repo structure may differ from the zip layout.
"""
import os
import re
import sys

LOG_FILE = "/data/adb/ssh/sshd.log"
CONFIG_FILE = "/data/adb/ssh/sshd_config"


def find_opensshd_init(root="."):
    """Recursively find all files named 'opensshd.init'."""
    found = []
    for dirpath, _, filenames in os.walk(root):
        if "opensshd.init" in filenames:
            found.append(os.path.join(dirpath, "opensshd.init"))
    return found


def patch_file(path):
    text = open(path).read()
    original = text

    # 1. Add -f CONFIG_FILE and -E LOG_FILE to bare $SSHD invocations (skip already patched lines)
    text = re.sub(
        r"(\$SSHD)(?!\s+-f)(?!\s+-E)(\s*$)",
        r"\1 -f " + CONFIG_FILE + " -E " + LOG_FILE + r"\2",
        text,
        flags=re.MULTILINE,
    )

    # 2. Ensure log directory exists before sshd starts
    text = text.replace(
        "start_service() {",
        "start_service() {\n    "
        "sed -Ei 's/^description=(\\[[^]]+\\][[:space:]]*)?/description=[✅Running] /g' /data/adb/modules/ssh/module.prop \n"
        "mkdir -p $(dirname " + LOG_FILE + ")",
        1,  # only replace first occurrence
    )

    # 3. Add stopped status to module.prop when service stops
    text = text.replace(
        "stop_service() {",
        "stop_service() {\n    "
        "sed -Ei 's/^description=(\\[[^]]+\\][[:space:]]*)?/description=[❌Stopped] /g' /data/adb/modules/ssh/module.prop \n",
        1,
    )

    # 4. Remove hardcoded absolute paths for standard binaries
    text = text.replace("CAT=/usr/bin/cat", "CAT=cat")
    text = text.replace("KILL=/usr/bin/kill", "KILL=kill")

    if text == original:
        print(f"[patch_init] No changes needed in: {path}")
        return False

    open(path, "w").write(text)
    print(f"[patch_init] Patched: {path}")
    for i, line in enumerate(text.splitlines(), 1):
        if "SSHD" in line or "mkdir" in line:
            print(f"  {i:3d}: {line.rstrip()}")
    return True


# --- Main ---
candidates = find_opensshd_init(".")
if not candidates:
    # Soft warning: log patching is an enhancement, not critical to the build
    print("[patch_init] Warning: opensshd.init not found anywhere in the repo tree.")
    print("[patch_init] Listing files for diagnosis:")
    for dirpath, _, filenames in os.walk("."):
        # Skip deep build/source trees to keep output manageable
        depth = dirpath.count(os.sep)
        if depth <= 3:
            for f in filenames:
                if f.endswith((".sh", ".init", ".mk")):
                    print(f"  {os.path.join(dirpath, f)}")
    sys.exit(0)  # Non-fatal: don't block the build

patched_any = False
for path in candidates:
    if patch_file(path):
        patched_any = True

if not patched_any:
    print("[patch_init] All opensshd.init files were already patched or unchanged.")
