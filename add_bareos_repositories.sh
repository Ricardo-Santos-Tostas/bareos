#!/bin/sh

set -u
set -e

PREFIX_DIR=""
# declare the Bareos repository
DOWNLOADSERVER="download.bareos.org"
URL="https://download.bareos.org/current/Debian_12"

# setup credentials for apt auth
# (required for download.bareos.com, subscription)
BAREOS_USERNAME="username_at_example.com"
BAREOS_PASSWORD="MySecretBareosPassword"

if [ "${DOWNLOADSERVER}" = "download.bareos.com" ] && [ -d "${PREFIX_DIR}/etc/apt/auth.conf.d/" ]; then
    cat <<EOT >"${PREFIX_DIR}/etc/apt/auth.conf.d/download_bareos_com.conf"
machine download.bareos.com
login ${BAREOS_USERNAME}
password ${BAREOS_PASSWORD}
EOT
    chmod 0600 "${PREFIX_DIR}/etc/apt/auth.conf.d/download_bareos_com.conf"
fi

# add the Bareos repository
cat <<EOT >"${PREFIX_DIR}/etc/apt/sources.list.d/bareos.sources"
Types: deb deb-src
URIs: ${URL}
Suites: /
Architectures: amd64
Signed-By: ${PREFIX_DIR}/etc/apt/keyrings/bareos-experimental.gpg
EOT

# add package key
mkdir -p "${PREFIX_DIR}/etc/apt/keyrings/"
# download key via
# wget -O /etc/apt/keyrings/bareos-experimental.gpg ${URL}/bareos-keyring.gpg
# or
cat << EOT | gpg --dearmor -o "${PREFIX_DIR}/etc/apt/keyrings/bareos-experimental.gpg"
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBF23EK4BEAC1FADpF6aaC93bxouVT6/BuXJajjtLkHNKfY26BYuvpwgLmVwp
M8vBuQWEPxxP6y2wXffv5bO/0Y1tS7tCW4i7duKz6W6as7/N13P/Mah8KOS0Zles
VM94fKXX8um7okqY9EwqgWVyHetW0PVpMKCsguMezv0IUmGAi/XX/GgJBeDYWvTh
S8DXtMhqWMXWv9yptJJsFQgdS0GVb8fcHG+Vl5GWmb+p8+R5x2JjLrP2OIoY8caD
boueBiUUeYnlPQqBa7flZSlBslSbk8qwnr75r/fX0/ihnFfLZol348AOCjPeWEYM
H3xQvuuyXsOg7dJ3dX4pE/MwUUOSlWyAACvCDYLQ+Xlvnt1j1dmbnGiBYRfn9cMZ
YEDZVSey7LwUwkXi9yXAc5+g6+OUUz1dIoZCyiAezttU8yfoiLXgilOHm7LniW4o
n5LIxTmo3pUSeEdQntFKd8jStIhvhGyKop1wlDU+FGUaxgWdswKE5se7WdaR6Em7
iuOMd9hZpS24Y4jeGjr4v4uwzB/Y8eB+vvM/ISGJltC8zgNpk81Dv1g2m/cy3YLb
POUxNy5+TAdO3UztuYbGQqgDax8RESD/6CbC8Z8X4TXYETjqtBR/9dNWBJCMb3aT
CXqZyc0YwiU0ISDCZhKbrPCkhwniOI4gqNz2pyFn9eUBw4xXx4DV0rQkyQARAQAB
tDRCYXJlb3MgZXhwZXJpbWVudGFsIFNpZ25pbmcgS2V5IDxzaWduaW5nQGJhcmVv
cy5jb20+iQJOBBMBCAA4AhsDAh4BAheAFiEEgoNM8ALYm6VcHtCqQtokpt/vkScF
AmXLUuMFCwkIBwIGFQoJCAsCBBYCAwEACgkQQtokpt/vkSc0DxAAnCyk0+LL4yZn
hL3AFKww0jgX++0QHYGZOFUoFyuqrPEtkjDAgBhNugPKejb15kRxhPuTHriXD9iO
O7F7hlnOGpnm/V11Gsu1k0tHgPYTS0U+ZkAtqTh/pWpKbEGV1tcUX2qMgoJRDopp
wUbnpQfFBGxqmqFZB4as7P4JkQRqMVCTGDsW3bmoTLYwi1IzB5YUPyfP7PxCvpwC
RHm/cidvRztiwUv5Y8ZD8b8G1B18klPNwTDkrGIj4MGTEDmuk82Ohu7Y44VpJ8mM
2kXv4z84VwqulYWj7t4WzxN8xpYMQw+2Yj9y1t4meYmlrG5df6MFlT7sW3DO4duJ
b5QI40B1RPhMeVUdrCAuNcsQxwpbcnDcuQZYKvkFhu8E2QBm+dQq6+y3fjbebvF5
y4GfwYGryNjlA3Vz24DylaN7k0VzccYGPK7WaPEgFI89OyqMdGveQR61xpe/1H/Q
GtQR1y3j6cR3K7M5cAJ0KIwA09lsOdcjd73Dl5xSmp8O9G/yf5Ybu/gDy422AeT3
KZ7zixRyB5NRSn6t51OehZOWZSQtMP8dkP2AzKkZs3GB3h2bREU6kMjY0BD7secV
eIeL6THtJhpm8OGacLSN/G4bDjxFpmlUxPH7nwL6zFCxPBoQubhzxgIIFSfKcB/E
iigZf6MxTddPMRaD36FLlataihx7mLQ=
=GxhN
-----END PGP PUBLIC KEY BLOCK-----
EOT

echo "Repository ${URL} successfully added."
