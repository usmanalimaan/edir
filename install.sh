#!/bin/sh
# CIMITRA EDIR PRACTICE INSTALL SCRIPT

set -e

CIMITRA_URI="https://raw.githubusercontent.com/cimitrasoftware/edir/main/install_cimitra_edir.sh"

curl -LJO --fail --location --progress-bar --output "install_cimitra_edir.sh" "$CIMITRA_URI"

chmod +x "./install_cimitra_edir.sh"

dos2unix ./install_cimitra_edir.sh

./install_cimitra_edir.sh