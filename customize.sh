##########################################################################
# MagiskSSH — customize.sh
# Modern replacement for the legacy install.sh.
#
# Called by Magisk/KernelSU during module installation.
# Available variables (provided by the framework):
#   SKIPUNZIP   MODPATH   ZIPFILE   ARCH   API   IS64BIT
#   KSU         KSU_VER   KSU_VER_CODE
##########################################################################

# Do not auto-extract the whole zip (we pick files explicitly below)
SKIPUNZIP=1

ui_print "***********************************"
ui_print "     SSH for Android (Magisk)      "
ui_print "     Patched by patched-MagiskSSH  "
ui_print "***********************************"

# ── Step 1: Validate minimum API ─────────────────────────────────────
if [ "$API" -lt 26 ]; then
  abort "ERROR: Android 8.0 (API 26) or higher is required."
fi

ui_print "- Target arch : $ARCH"
ui_print "- Android API : $API"
[ "$KSU" = "true" ] && ui_print "- Running under KernelSU ($KSU_VER)"

# ── Step 2: Prepare module directory layout ───────────────────────────
ui_print "- Preparing module directories"
mkdir -p "$MODPATH/system/bin"
mkdir -p "$MODPATH/system/usr/libexec/ssh-core"

# ── Step 3: Extract arch-independent module files ─────────────────────
ui_print "- Extracting opensshd.init and wrapper"
unzip -o "$ZIPFILE" 'common/opensshd.init' -d "$MODPATH" >/dev/null 2>&1
unzip -o "$ZIPFILE" 'common/wrapper'       -d "$MODPATH" >/dev/null 2>&1
mv "$MODPATH/common/opensshd.init" "$MODPATH/opensshd.init"
mv "$MODPATH/common/wrapper"       "$MODPATH/system/usr/libexec/ssh-core/wrapper"
rmdir "$MODPATH/common" 2>/dev/null || true

# ── Step 4: Extract arch-specific binaries ────────────────────────────
ui_print "- Extracting binaries for arch: $ARCH"
TMPDIR="$MODPATH/tmp"
mkdir -p "$TMPDIR"
unzip -o "$ZIPFILE" "arch/$ARCH/*" -d "$TMPDIR" >/dev/null 2>&1
mv "$TMPDIR/arch/$ARCH/lib" "$MODPATH/system/usr/lib"
mv "$TMPDIR/arch/$ARCH/bin/"* "$MODPATH/system/usr/libexec/ssh-core/"
rm -rf "$TMPDIR"

# ── Step 5: Create binary symlinks via wrapper ────────────────────────
ui_print "- Creating symlinks in /system/bin"
for f in scp sftp sftp-server ssh ssh-keygen sshd sshd-session sshd-auth rsync; do
  ln -sf /system/usr/libexec/ssh-core/wrapper "$MODPATH/system/bin/$f"
done

# ── Step 6: Extract injected WebUI and scripts ────────────────────────
if unzip -l "$ZIPFILE" 'webroot/*' >/dev/null 2>&1; then
  ui_print "- Extracting WebUI"
  unzip -o "$ZIPFILE" 'webroot/*' -d "$MODPATH" >/dev/null 2>&1
fi

if unzip -l "$ZIPFILE" 'scripts/*' >/dev/null 2>&1; then
  ui_print "- Extracting scripts"
  unzip -o "$ZIPFILE" 'scripts/*' -d "$MODPATH" >/dev/null 2>&1
fi

# ── Step 7: Ensure persistent SSH data directories exist ──────────────
ui_print "- Creating SSH data directories in /data/adb/ssh"
mkdir -p /data/adb/ssh /data/adb/ssh/root/.ssh /data/adb/ssh/shell/.ssh

# Copy default sshd_config only if none exists yet
if [ ! -f /data/adb/ssh/sshd_config ]; then
  ui_print "- Installing default sshd_config"
  unzip -o "$ZIPFILE" 'common/sshd_config' -d "$MODPATH/tmp2" >/dev/null 2>&1
  mv "$MODPATH/tmp2/common/sshd_config" /data/adb/ssh/sshd_config
  rm -rf "$MODPATH/tmp2"
fi

# Ensure authorized_keys files exist
for keyfile in /data/adb/ssh/root/.ssh/authorized_keys /data/adb/ssh/shell/.ssh/authorized_keys; do
  [ -f "$keyfile" ] || touch "$keyfile"
  chmod 600 "$keyfile"
done

# ── Step 8: Set permissions ───────────────────────────────────────────
ui_print "- Setting permissions"
set_perm_recursive "$MODPATH"                          0 0 0755 0644
set_perm_recursive "$MODPATH/system/usr/libexec/ssh-core" 0 0 0755 0755
set_perm           "$MODPATH/opensshd.init"            0 0 0755

# Make injected scripts executable
[ -d "$MODPATH/scripts" ] && set_perm_recursive "$MODPATH/scripts" 0 0 0755 0755
[ -f "$MODPATH/action.sh" ] && set_perm "$MODPATH/action.sh" 0 0 0755

# Symlinks in /system/bin need proper SELinux context and ownership
chcon -h u:object_r:system_file:s0 "$MODPATH/system/bin/"*
chown -h root:shell "$MODPATH/system/bin/"*

# Persistent data permissions
chown shell:shell /data/adb/ssh/shell /data/adb/ssh/shell/.ssh
chown root:root   /data/adb/ssh/root  /data/adb/ssh/root/.ssh
chmod 700 /data/adb/ssh/shell /data/adb/ssh/root
chmod 700 /data/adb/ssh/shell/.ssh /data/adb/ssh/root/.ssh
[ -f /data/adb/ssh/sshd_config ] && chmod 600 /data/adb/ssh/sshd_config

ui_print "- Installation complete!"
