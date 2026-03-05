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

# ── Step 3: Extract all files at once ────────────────────────────────
ui_print "- Extracting module files"
EXTRACT_TMP="$MODPATH/.tmp_extract"
mkdir -p "$EXTRACT_TMP"
unzip -o "$ZIPFILE" -d "$EXTRACT_TMP" >/dev/null 2>&1

# ── Step 4: Move arch-independent files ──────────────────────────────
mv "$EXTRACT_TMP/common/opensshd.init" "$MODPATH/opensshd.init"
mv "$EXTRACT_TMP/common/wrapper"       "$MODPATH/system/usr/libexec/ssh-core/wrapper"

# ── Step 5: Move arch-specific binaries ──────────────────────────────
ui_print "- Installing binaries for arch: $ARCH"
mv "$EXTRACT_TMP/arch/$ARCH/lib"    "$MODPATH/system/usr/lib"
mv "$EXTRACT_TMP/arch/$ARCH/bin/"*  "$MODPATH/system/usr/libexec/ssh-core/"
rm -rf $EXTRACT_TMP/arch
# ── Step 6: Move optional WebUI and scripts ───────────────────────────
[ -d "$EXTRACT_TMP/webroot" ]  && { ui_print "- Installing WebUI";  mv "$EXTRACT_TMP/webroot"  "$MODPATH/"; }
mv "$EXTRACT_TMP/scripts/"    "$MODPATH/"

# ── Step 7: Ensure persistent SSH data directories exist ──────────────
ui_print "- Creating SSH data directories in /data/adb/ssh"
mkdir -p /data/adb/ssh /data/adb/ssh/root/.ssh /data/adb/ssh/shell/.ssh

# Copy default sshd_config only if none exists yet
if [ ! -f /data/adb/ssh/sshd_config ]; then
  ui_print "- Installing default sshd_config"
  mv "$EXTRACT_TMP/common/sshd_config" /data/adb/ssh/sshd_config
fi
rm -rf $EXTRACT_TMP/common $EXTRACT_TMP/META-INF
mv $EXTRACT_TMP/* "$MODPATH/"
# ── Cleanup temp dir ──────────────────────────────────────────────────
rm -rf "$EXTRACT_TMP"

# ── Step 8: Create binary symlinks via wrapper ────────────────────────
ui_print "- Creating symlinks in /system/bin"
for f in scp sftp sftp-server ssh ssh-keygen sshd sshd-session sshd-auth rsync; do
  ln -sf /system/usr/libexec/ssh-core/wrapper "$MODPATH/system/bin/$f"
done

# ── Step 9: Set permissions ───────────────────────────────────────────
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

ui_print "- Persistent data permissions"
chown shell:shell /data/adb/ssh/shell /data/adb/ssh/shell/.ssh
chown root:root   /data/adb/ssh/root  /data/adb/ssh/root/.ssh
chmod 700 /data/adb/ssh/shell /data/adb/ssh/root
chmod 700 /data/adb/ssh/shell/.ssh /data/adb/ssh/root/.ssh
[ -f /data/adb/ssh/sshd_config ] && chmod 600 /data/adb/ssh/sshd_config

ui_print "- Installation complete!"
