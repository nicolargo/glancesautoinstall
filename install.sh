#!/usr/bin/env bash
#
# GlancesAutoInstall script
# Version: 0.1
# Author:  Nicolas Hennion (aka) Nicolargo
#

distrib_name=`lsb_release -is`
distrib_version=`lsb_release -rs`

do_with_root() {
    # already root? "Just do it" (tm).
    if [[ `whoami` = 'root' ]]; then
        $*
    elif [[ -x /bin/sudo || -x /usr/bin/sudo ]]; then
        echo "sudo $*"
        sudo $*
    else
        echo "Glances requires root privileges to install." 
        echo "Please run this script as root."
        exit 1
    fi
}

echo "Detected system:" $distrib_name $distrib_version
if [[ $distrib_name == "Ubuntu" || $distrib_name == "Debian" ]]; then
    # Debian/Ubuntu

    # Set non interactive mode
    set -eo pipefail
    export DEBIAN_FRONTEND=noninteractive

    # Make sure the package repository is up to date
    do_with_root apt-get -y update

    # Install prerequirement
    do_with_root apt-get install -y python-dev python-pip git lm-sensors
    do_with_root pip install psutil bottle batinfo https://bitbucket.org/gleb_zhulik/py3sensors/get/tip.tar.gz

    # Install or ugrade Glances from the Pipy repository
    if [[ -x /usr/local/bin/glances ]]; then
        do_with_root pip install --upgrade glances
    else
        do_with_root pip install glances
    fi
else
    # Unsupported system
    echo "Sorry, GlancesAutoInstall script is not compliant with your system."
    echo "Pleae read: https://github.com/nicolargo/glances#installation"
fi 