# mac80211_hwsim test setup

Short guide to building hostap/wpa_supplicant and running hwsim tests without touching system Wi-Fi.

## Prerequisites

- Linux with mac80211_hwsim (usually built-in or as module).
- MbedTLS 3.6.5 dev/lib (e.g. from distro) if using TLS=mbedtls.
- Run test scripts from `tests/hwsim` with `sudo` (needed for loading modules and sockets).

## Compiling

From the repo root (or the given subdir): The .config is already updated with appropriate configs.

**hostapd**

```bash
cd hostapd
# Ensure .config has CONFIG_TLS=mbedtls, CONFIG_SAE=y, CONFIG_TESTING_OPTIONS=y
# (and adjust LIBS/CFLAGS for mbedtls if needed; see README)
make -j4
```

**wpa_supplicant**

```bash
cd wpa_supplicant
# Ensure .config has CONFIG_TLS=mbedtls, CONFIG_PMKSA_CACHE_EXTERNAL=y,
# CONFIG_TESTING_OPTIONS=y (for EAP test connectivity checks)
make -j4
```

SAE needs the options above; without them the SAE test fails. EAP tests (PEAP, EAP-TLS,
EAP-TTLS) need the RADIUS auth server and wpa_supplicant CONFIG_TESTING_OPTIONS=y (see
below).

## NetworkManager setup (recommended)

So that tests do not conflict with NM and `stop.sh` does not kill the system wpa_supplicant:

1. Copy the unmanage config and reload NM (once):

   ```bash
   sudo cp tests/hwsim/networkmanager-unmanage-wlan.conf /etc/NetworkManager/conf.d/
   sudo systemctl reload NetworkManager
   ```

2. Then `stop.sh` only kills processes whose PIDs are in `logs/current/*.pids` (written by `start.sh`), not all hostapd/wpa_supplicant on the system.

Your normal Wi-Fi (e.g. Ethernet, other interfaces) is unchanged; only the `wlan*` names used by hwsim are unmanaged.

## Loading hwsim and running tests

- **Load mac80211_hwsim** (if not already loaded):

  ```bash
  sudo modprobe mac80211_hwsim
  ```

- **Quick run (WPA2-PSK and SAE)**:

  ```bash
  cd tests/hwsim
  sudo ./run-simple-mbedtls.sh
  ```

  This runs `stop.sh`, `start.sh` with `SKIP_AUTH_SERV=1` (hostapd, wpa_supplicant only), the two tests, then `stop.sh`. PEAP is not run (see below).

- **Manual start/stop**:

  ```bash
  cd tests/hwsim
  sudo ./start.sh          # use SKIP_AUTH_SERV=1 to skip auth server
  ./run-tests.py -q <name> # run one test, e.g. ap_wpa2_psk, sae
  sudo ./stop.sh           # stop only test PIDs (when using NM unmanage)
  ```

- **Run a single test by name**:

  ```bash
  ./run-tests.py -q ap_wpa2_psk
  ./run-tests.py -q sae
  ./run-tests.py -q ap_wpa2_eap_peap_eap_mschapv2
  ./run-tests.py -q ap_wpa2_eap_tls
  ./run-tests.py -q ap_wpa2_eap_ttls_eap_mschapv2
  ```

**EAP tests (PEAP, EAP-TLS, EAP-TTLS):** These need the RADIUS auth server and
wpa_supplicant built with CONFIG_TESTING_OPTIONS=y (for DATA_TEST_CONFIG in the
connectivity step). The auth server expects hostapd built with RADIUS server,
`driver=none`, EAP-PWD, EAP-FAST, EAP-SIM, and related options. Start without
SKIP_AUTH_SERV (`NO_DBUS=1 ./start.sh`). If start fails with "Could not connect
to hostapd-as-RADIUS-server", check `logs/<timestamp>/auth_serv` for
config/build errors.

## Logs

- Default log dir: `tests/hwsim/logs/current/` (or `$LOGDIR` if set).
- Per-test logs: e.g. `logs/current/sae.log`, `logs/current/hostapd`, `logs/current/auth_serv`.
- If a test fails, check the corresponding log and `auth_serv` when running EAP tests.

## Unloading hwsim

```bash
sudo rmmod mac80211_hwsim
```

If the module is in use (e.g. by other Wi-Fi drivers), unload those first or leave hwsim loaded.
