#! /usr/bin/env sh

set -eux

URI=https://jan-matejka.github.io/debian-ppa
KEY=/etc/apt/trusted.gpg.d/jma-ppa.key
FP=D059E95DB734392F42329FF6AD577215EA45A9341EA1773712FEA1693F291BD658EC029314ED8CC2FBE81E011EBB37CA691C591F2B524183A4D7D908
apt_src=/etc/apt/sources.list.d/

curl -s --compressed $URI/jma-ppa.key
curl -s --compressed $URI/jma-ppa.key -o $KEY
[ $(gpg -q --show-keys --with-colons $KEY | awk -F: '$1 == "fpr" { printf $10 }') = $FP ] || {
  echo 'fingerprint mismatch'
  exit 1
}

curl -s --compressed $URI/dists/$(awk -F= '$1=="VERSION_CODENAME" {print $2}' /etc/os-release)/jma-ppa.sources -o $apt_src/jma-ppa.sources

apt-get update
