#!/bin/sh

DIR="$(cd "$(dirname "$0")" && pwd)"
PIDDIR=""
if [ -d "$DIR/logs/current" ]; then
    PIDDIR="$DIR/logs/current"
fi

# Never killall wpa_supplicant or hostapd - that would kill system WiFi (e.g. NM).
# Only kill test processes by PID when start.sh left PID files in logs/current.
HAVE_PIDS=0
if [ -n "$PIDDIR" ] && [ -f "$PIDDIR/wpa_supplicant.pids" ]; then
    HAVE_PIDS=1
fi

if pidof wpa_supplicant hostapd valgrind.bin hlr_auc_gw wlantest > /dev/null; then
    RUNNING=yes
else
    RUNNING=no
fi

if [ "$HAVE_PIDS" = "1" ]; then
    [ -f "$PIDDIR/hostapd.pids" ] && while read p; do sudo kill $p 2>/dev/null; done < "$PIDDIR/hostapd.pids"
    [ -f "$PIDDIR/wpa_supplicant.pids" ] && while read p; do sudo kill $p 2>/dev/null; done < "$PIDDIR/wpa_supplicant.pids"
    [ -f "$PIDDIR/wlantest.pid" ] && while read p; do sudo kill $p 2>/dev/null; done < "$PIDDIR/wlantest.pid"
    [ -f "$PIDDIR/hlr_auc_gw.pid" ] && while read p; do sudo kill $p 2>/dev/null; done < "$PIDDIR/hlr_auc_gw.pid"
    [ -f "$PIDDIR/auth_serv.pids" ] && while read p; do sudo kill $p 2>/dev/null; done < "$PIDDIR/auth_serv.pids"
    for i in `pidof valgrind.bin`; do
	if ps $i | grep -q -E "wpa_supplicant|hostapd"; then
	    sudo kill $i 2>/dev/null
	fi
    done
else
    sudo killall -q wlantest
    for i in `pidof valgrind.bin`; do
	if ps $i | grep -q -E "wpa_supplicant|hostapd"; then
	    sudo kill $i
	fi
    done
fi

if grep -q hwsim0 /proc/net/dev; then
    sudo ip link set hwsim0 down
fi

if [ -e /tmp/hlr_auc_gw.sock ]; then
    if which socat > /dev/null; then
	echo TERMINATE | socat - UNIX-SENDTO:/tmp/hlr_auc_gw.sock
	sleep 0.1
    fi
fi

if [ "$HAVE_PIDS" = "1" ]; then
    : # hlr_auc_gw already killed by PID above
else
    sudo killall -q hlr_auc_gw
fi

if [ "$RUNNING" = "yes" ]; then
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
	if ! pidof wpa_supplicant hostapd valgrind.bin hlr_auc_gw > /dev/null; then
	    break
	fi
	if [ $i -gt 10 ]; then
	    echo "Waiting for processes to exit (1)"
	    sleep 1
	else
	    sleep 0.06
	fi
    done
fi

if [ "$HAVE_PIDS" = "1" ] && pidof wpa_supplicant hostapd hlr_auc_gw > /dev/null; then
    sudo kill -9 $(cat "$PIDDIR/wpa_supplicant.pids" "$PIDDIR/hostapd.pids" \
	"$PIDDIR/hlr_auc_gw.pid" "$PIDDIR/auth_serv.pids" 2>/dev/null) 2>/dev/null
fi
# Never killall wpa_supplicant/hostapd - would kill system WiFi.

for i in `pidof valgrind.bin`; do
    if ps $i | grep -q -E "wpa_supplicant|hostapd"; then
	echo "wpa_supplicant/hostapd(valgrind) did not exit - try to force it to die"
	sudo kill -9 $i
    fi
done

count=0
for i in /tmp/wpas-wlan0 /tmp/wpas-wlan1 /tmp/wpas-wlan2 /tmp/wpas-wlan5 /tmp/wpas-wlan6 /tmp/wpas-wlan7 /var/run/hostapd-global /tmp/hlr_auc_gw.sock /tmp/wpa_ctrl_* /tmp/eap_sim_db_*; do
    count=$(($count + 1))
    if [ $count -lt 8 -a -e $i ]; then
	echo "Waiting for ctrl_iface $i to disappear"
	sleep 1
    fi
    if [ -e $i ]; then
	echo "Control interface file $i exists - remove it"
	sudo rm $i
    fi
done

# Per-interface ctrl sockets from p2p*.conf (DIR=/var/run/wpa_supplicant)
for i in /var/run/wpa_supplicant/wlan0 /var/run/wpa_supplicant/wlan1 \
    /var/run/wpa_supplicant/wlan2; do
    if [ -e "$i" ]; then
	echo "Removing stale ctrl_iface $i"
	sudo rm -f "$i"
    fi
done

if grep -q mac80211_hwsim /proc/modules 2>/dev/null ; then
    sudo rmmod mac80211_hwsim
    sudo rmmod mac80211
    sudo rmmod cfg80211
    # wait at the end to avoid issues starting something new immediately after
    # this script returns
    sleep 1
fi
