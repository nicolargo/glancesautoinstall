#!/usr/bin/env bash
#
# GlancesAutoInstall develop branch script
# Version: DEVELOP branch
# Author:  Nicolas Hennion (aka) Nicolargo
#

PYTHON_VERSION=`python -c 'import sys; print("%i" % (sys.hexversion<0x02070000))'`

if [ $PYTHON_VERSION -ne 0 ]
then
    echo "Python 2.7 or higher is needed..."
    exit 1
fi

# Execute a command as root (or sudo)
do_with_root() {
    # already root? "Just do it" (tm).
    if [[ `whoami` = 'root' ]]; then
        $*
    elif [[ -x /bin/sudo || -x /usr/bin/sudo ]]; then
        echo "sudo $*"
        sudo $*
    else
        echo "Glances develop requires root privileges to install."
        echo "Please run this script as root."
        exit 1
    fi
}

# Detect distribution name
if [[ `which lsb_release 2>/dev/null` ]]; then
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
            echo "Sorry, GlancesAutoInstall develop branch script is not compliant with your system."
            echo "Please read: https://github.com/nicolargo/glances#installation"
            exit 1
        fi
    done
fi

echo "Detected system:" $distrib_name

shopt -s nocasematch
# Let's do the installation
if [[ $distrib_name == "ubuntu" || $distrib_name == "LinuxMint" || $distrib_name == "debian" || $distrib_name == "Raspbian" ]]; then
    # Ubuntu/Debian variants

    # Set non interactive mode
    set -eo pipefail
    export DEBIAN_FRONTEND=noninteractive

    # Make sure the package repository is up to date
    do_with_root apt-get -y update

    # Install prerequirements
    do_with_root apt-get install -y git python-pip python-dev gcc lm-sensors wireless-tools

elif [[ $distrib_name == "redhat" ||  $distrib_name == "RedHatEnterpriseServer" || $distrib_name == "fedora" || $distrib_name == "centos" ]]; then
    # Redhat/Fedora/CentOS

    # Install prerequirements
    do_with_root yum -y install git python-pip python-devel gcc lm_sensors wireless-tools

elif [[ $distrib_name == "arch" ]]; then
    # Arch support

    # Headers not needed for Arch, shipped with regular python packages
    do_with_root pacman -S python-pip lm_sensors wireless_tools --noconfirm

else
    # Unsupported system
    echo "Sorry, GlancesAutoInstall develop branch script is not compliant with your system."
    echo "Please read: https://github.com/nicolargo/glances#installation"
    exit 1

fi
shopt -u nocasematch

# Install or ugrade Glances from the Git develop repository
git clone -b develop https://github.com/nicolargo/glances.git

# Install libs
# Glances issue #922: Do not install Sensors: PySensors
do_with_root pip install -r glances/requirements.txt
do_with_root pip install -r glances/optional-requirements.txt
