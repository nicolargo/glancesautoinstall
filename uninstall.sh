#!/usr/bin/env bash
#
# Glances uninstall script
# It will uninstall Glances and all its dependancies installed with
# the GlancesAutoInstall script
#
# Version: MASTER branch
# Author:  Nicolas Hennion (aka) Nicolargo
#

# Execute a command as root (or sudo)
do_with_root() {
    # already root? "Just do it" (tm).
    if [[ `whoami` = 'root' ]]; then
        $*
    elif [[ -x /bin/sudo || -x /usr/bin/sudo ]]; then
        echo "sudo $*"
        sudo $*
    else
        echo "Glances requires root privileges to uninstall."
        echo "Please run this script as root."
        exit 1
    fi
}

# Install or ugrade Glances from the Pipy repository
if [[ -x /usr/local/bin/glances || -x /usr/bin/glances ]]; then
    echo "Uninstall Glances dependancies"
    DEPS="setuptools glances[action,batinfo,browser,cpuinfo,chart,docker,export,folders,gpu,ip,raid,snmp,web,wifi]"
    do_with_root pip uninstall $DEPS

    echo "Uninstall Glances"
    do_with_root pip uninstall glances
else
    echo "Error: Glances is not found in your system"
    echo "Note: This script only work if you have installed Glances with the GlancesAutoInstall script"
fi
