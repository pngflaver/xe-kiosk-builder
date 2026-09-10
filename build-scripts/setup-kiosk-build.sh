#!/bin/bash
set -e

BUILD_DIR="/root/kiosk-build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Cleaning previous builds..."
lb clean || true

echo "Configuring live-build for Debian Bookworm..."
lb config \
    --distribution bookworm \
    --architecture amd64 \
    --archive-areas "main contrib non-free non-free-firmware" \
    --apt-recommends false \
    --iso-volume "JUMPBOX-KIOSK" \
    --linux-packages "linux-image" \
    --bootappend-live "boot=live components quiet splash nosudo noroot username=user ethdevice-timeout=60"

echo "Setting up package list..."
mkdir -p config/package-lists
cat <<'EOF' > config/package-lists/kiosk.list.chroot
# Live essentials
live-boot
live-config
systemd-sysv

# X11 & Display Manager
xserver-xorg
xserver-xorg-video-all
x11-xserver-utils
lightdm
openbox

# Kiosk applications
firefox-esr

# Firmware (Realtek NIC required for target PXE laptop)
firmware-realtek

# Networking
network-manager
curl
EOF

echo "Hardening X11 (disabling VT switching and termination)..."
mkdir -p config/includes.chroot/etc/X11/xorg.conf.d
cat <<'EOF' > config/includes.chroot/etc/X11/xorg.conf.d/10-kiosk.conf
Section "ServerFlags"
    Option "DontVTSwitch" "true"
    Option "DontZap" "true"
EndSection
EOF

echo "Configuring auto-login via LightDM..."
mkdir -p config/includes.chroot/etc/lightdm/lightdm.conf.d
cat <<'EOF' > config/includes.chroot/etc/lightdm/lightdm.conf.d/10-autologin.conf
[Seat:*]
autologin-user=user
autologin-user-timeout=0
user-session=openbox
allow-guest=false
EOF

echo "Configuring Firefox Enterprise Policies (Lockdown)..."
mkdir -p config/includes.chroot/etc/firefox-esr/policies
cat <<'EOF' > config/includes.chroot/etc/firefox-esr/policies/policies.json
{
  "policies": {
    "DisableAppUpdate": true,
    "DisableDeveloperTools": true,
    "DisableFirefoxAccounts": true,
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "DisablePrivateBrowsing": true,
    "DisableProfileImport": true,
    "DisableSafeMode": true,
    "DontCheckDefaultBrowser": true,
    "Homepage": {
      "URL": "http://<YOUR_JUMPBOX_URL>",
      "Locked": true,
      "StartPage": "homepage"
    },
    "NoDefaultBookmarks": true,
    "OfferToSaveLogins": false,
    "PasswordManagerEnabled": false,
    "PromptForDownload": false,
    "SanitizeOnShutdown": true,
    "URLBlocklist": [
      "file://*"
    ]
  }
}
EOF

echo "Hardening Openbox configuration (removing key/mouse bindings)..."
mkdir -p config/includes.chroot/etc/skel/.config/openbox
cat <<'EOF' > config/includes.chroot/etc/skel/.config/openbox/rc.xml
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <keyboard></keyboard>
  <mouse>
    <context name="Root"></context>
  </mouse>
  <applications>
    <application class="*">
      <decor>no</decor>
      <fullscreen>yes</fullscreen>
      <maximized>yes</maximized>
    </application>
  </applications>
</openbox_config>
EOF

cat <<'EOF' > config/includes.chroot/etc/skel/.config/openbox/menu.xml
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
</openbox_menu>
EOF

echo "Configuring Openbox autostart with watchdog restart loop..."
cat <<'EOF' > config/includes.chroot/etc/skel/.config/openbox/autostart
# Disable screen blanking and power saving
xset s off
xset -dpms
xset s noblank

# Wait for STP forward transition and network reachability (up to 60s)
for i in $(seq 1 60); do
    if curl -s --head --connect-timeout 2 "http://<YOUR_JUMPBOX_URL>" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Supervised Firefox Kiosk Loop
(
    while true; do
        firefox-esr --kiosk "http://<YOUR_JUMPBOX_URL>"
        sleep 1
    done
) &
EOF
chmod +x config/includes.chroot/etc/skel/.config/openbox/autostart

echo "Build environment setup complete in $BUILD_DIR."
echo "To build the ISO, run: cd $BUILD_DIR && lb build"
