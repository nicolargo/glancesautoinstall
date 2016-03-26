#!/usr/bin/env bash
#
# GlancesAutoInstall script
# Version: 2.4
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
        echo "Glances requires root privileges to install."
        echo "Please run this script as root."
        exit 1
    fi
}

# Detect distribution name
if [[ `which lsb_releaseX 2>/dev/null` ]]; then
    # lsb_release available
    distrib_name=`lsb_release -is`
else
    # lsb_release not available
    lsb_files=`find /etc -type f -maxdepth 1 \( ! -wholename /etc/os-release ! -wholename /etc/lsb-release -wholename /etc/\*release -o -wholename /etc/\*version \) 2> /dev/null`
    for file in $lsb_files; do
        if [[ $file =~ /etc/(.*)[-_] ]]; then
            distrib_name=${BASH_REMATCH[1]}
            break
        else
            echo "Sorry, GlancesAutoInstall script is not compliant with your system."
            echo "Please read: https://github.com/nicolargo/glances#installation"
            exit 1
        fi
    done
fi

echo "Detected system:" $distrib_name

shopt -s nocasematch
# Let's do the installation
if [[ $distrib_name == "ubuntu" || $distrib_name == "debian" ]]; then
    # Debian/Ubuntu

    # Set non interactive mode
    set -eo pipefail
    export DEBIAN_FRONTEND=noninteractive

    # Make sure the package repository is up to date
    do_with_root apt-get -y --force-yes update

    # Install prerequirements
    do_with_root apt-get install -y --force-yes python-dev python-pip lm-sensors

elif [[ $distrib_name == "redhat" || $distrib_name == "centos" || $distrib_name == "Scientific" ]]; then
    # Redhat/CentOS/SL

    # Install prerequirements
    do_with_root yum -y install python-pip python-devel gcc lm_sensors

elif [[ $distrib_name == "fedora" ]]; then
    # Fedora

    # Install prerequirements
    do_with_root dnf -y install python-pip python-devel gcc lm_sensors

elif [[ $distrib_name == "arch" ]]; then
    # Arch support

    # Headers not needed for Arch, shipped with regular python packages
    do_with_root pacman -S python-pip lm_sensors --noconfirm

else
    # Unsupported system
    echo "Sorry, GlancesAutoInstall script is not compliant with your system."
    echo "Please read: https://github.com/nicolargo/glances#installation"
    exit 1

fi
shopt -u nocasematch

# Install libs
echo "Install dependancies"
do_with_root pip install psutil logutils bottle batinfo https://bitbucket.org/gleb_zhulik/py3sensors/get/tip.tar.gz zeroconf netifaces pymdstat influxdb elasticsearch potsdb statsd pystache docker-py pysnmp pika py-cpuinfo bernhard

# Install or ugrade Glances from the Pipy repository
if [[ -x /usr/local/bin/glances || -x /usr/bin/glances ]]; then
    echo "Upgrade Glances and dependancies"
    # Install libs
    do_with_root pip install --upgrade psutil logutils bottle batinfo https://bitbucket.org/gleb_zhulik/py3sensors/get/tip.tar.gz zeroconf netifaces pymdstat influxdb elasticsearch potsdb statsd pystache docker-py pysnmp pika py-cpuinfo bernhard
    do_with_root pip install --upgrade glances
else
    echo "Install Glances"
    # Install Glances
    do_with_root pip install glances
fi
