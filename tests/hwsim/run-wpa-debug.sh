#!/bin/sh
#
# Run the first wpa_supplicant (wlan0) in the foreground with the same
# arguments as start.sh, so init failures are visible on the terminal.
# Use this when start.sh fails with "Failed to initialize wpa_supplicant".
#
# Prereqs: mac80211_hwsim loaded (start.sh or: sudo modprobe mac80211_hwsim radios=7)
#          If wlan0 is not hwsim, unload other WiFi drivers or use -i <iface>.
#

DIR="$(cd "$(dirname "$0")" && pwd)"
WPAS=$DIR/../../wpa_supplicant/wpa_supplicant

if [ -z "$LOGDIR" ]; then
    LOGDIR="$DIR/logs/debug-$$"
    mkdir -p "$LOGDIR"
fi

if groups | tr ' ' '\n' | grep -q ^admin$; then
    GROUP=admin
elif groups | tr ' ' '\n' | grep -q ^wheel$; then
    GROUP=wheel
else
    GROUP=adm
fi

for i in 0 1 2; do
    sed "s/ GROUP=.*$/ GROUP=$GROUP/" "$DIR/p2p$i.conf" > "$LOGDIR/p2p$i.conf"
done

# Optional: use first available phy# if wlan0 does not exist
IFACE="${1:-wlan0}"
if [ -n "$1" ]; then
    shift
fi

# Remove stale ctrl sockets so we can start clean when run without stop.sh
[ -e /tmp/wpas-wlan0 ] && sudo rm -f /tmp/wpas-wlan0
[ -e "/var/run/wpa_supplicant/$IFACE" ] && sudo rm -f "/var/run/wpa_supplicant/$IFACE"

echo "LOGDIR=$LOGDIR"
echo "Interface: $IFACE (use: $0 <iface> to override)"
echo "Running wpa_supplicant in foreground (no -f); exit with Ctrl+C."
echo "---"

sudo "$WPAS" -g /tmp/wpas-wlan0 -G"$GROUP" -Dnl80211 -i"$IFACE" \
    -c "$LOGDIR/p2p0.conf" -dd
