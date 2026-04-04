#!/bin/bash

log_info "Applying Ubuntu Dock customization..."
if ! command -v gsettings &> /dev/null; then
    log_warning "gsettings not available. Skipping Dock customization."
    return 0
fi

USER_DBUS_SOCKET="/run/user/$(id -u "$REAL_USER")/bus"
if [ ! -S "$USER_DBUS_SOCKET" ]; then
    log_warning "Could not find session bus for $REAL_USER at $USER_DBUS_SOCKET. Skip Dock customization and run commands after logging into GNOME."
    return 0
fi

USER_DBUS_ADDRESS="unix:path=$USER_DBUS_SOCKET"
DISPLAY_VALUE="${DISPLAY:-:0}"

if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'"; then
    log_info "Dock positioned at the bottom"
else
    log_warning "Failed to reposition Dock. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'"
fi

if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false"; then
    log_info "Dock stretch disabled"
else
    log_warning "Failed to disable Dock stretch. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false"
fi

if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true"; then
    log_info "Dock enabled on all monitors"
else
    log_warning "Failed to enable Dock on all monitors. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true"
fi

if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false"; then
    log_info "Dock will auto-hide when not focused"
else
    log_warning "Failed to enable Dock auto-hide. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false"
fi

if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock autohide true"; then
    log_info "Dock autohide preference enforced"
else
    log_warning "Failed to set Dock autohide. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock autohide true"
fi

if run_as_user "DBUS_SESSION_BUS_ADDRESS='$USER_DBUS_ADDRESS' DISPLAY='$DISPLAY_VALUE' gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 36"; then
    log_info "Dock icon size set to 36px"
else
    log_warning "Failed to set Dock icon size. Run manually: gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 36"
fi
