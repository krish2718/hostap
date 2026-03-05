#!/bin/sh
# Run WPA2-PSK, WPA3-SAE and EAP (PEAP, EAP-TLS, EAP-TTLS) tests with mac80211_hwsim
# using mbedtls-built hostapd and wpa_supplicant. Run from tests/hwsim.
# Prereqs: hostapd and wpa_supplicant built with CONFIG_TLS=mbedtls (3.6.5).
# hostapd must have CONFIG_DRIVER_NONE, CONFIG_RADIUS_SERVER, CONFIG_EAP_PWD,
# CONFIG_EAP_SIM, CONFIG_EAP_FAST, CONFIG_HS20, and CFLAGS += -DCONFIG_RADIUS_TEST
# for the auth server (EAP tests). wpa_supplicant needs CONFIG_TESTING_OPTIONS=y
# for connectivity checks. To avoid killing system WiFi, exclude wlan* from
# NetworkManager once: sudo cp networkmanager-unmanage-wlan.conf
# /etc/NetworkManager/conf.d/ && sudo systemctl reload NetworkManager.

set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "=== Stopping any existing test env ==="
./stop.sh 2>/dev/null || true

echo "=== Starting hwsim (hostapd + wpa_supplicant + auth server from this tree) ==="
if ! NO_DBUS=1 ./start.sh; then
    echo "start.sh failed (mac80211_hwsim loaded? sudo?)"
    exit 1
fi

err=0
echo "=== Running WPA2-PSK test (test_ap_wpa2_psk) ==="
./run-tests.py -q ap_wpa2_psk || err=1

echo "=== Running WPA3-SAE test (test_sae) ==="
./run-tests.py -q sae || err=1

echo "=== Running EAP-PEAP-MSCHAPv2 test (test_ap_wpa2_eap_peap_eap_mschapv2) ==="
./run-tests.py -q ap_wpa2_eap_peap_eap_mschapv2 || err=1

echo "=== Running EAP-TLS test (test_ap_wpa2_eap_tls) ==="
./run-tests.py -q ap_wpa2_eap_tls || err=1

echo "=== Running EAP-TTLS/EAP-MSCHAPv2 test (test_ap_wpa2_eap_ttls_eap_mschapv2) ==="
./run-tests.py -q ap_wpa2_eap_ttls_eap_mschapv2 || err=1

echo "=== Stopping test env ==="
./stop.sh

if [ "$err" = "1" ]; then
    echo "One or more tests failed. Check logs in logs/current/ (or \$LOGDIR)."
    exit 1
fi
echo "All tests passed. Logs in logs/current/ (or \$LOGDIR)."
