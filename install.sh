#!/usr/bin/env bash
#
# GlancesAutoInstall script
# Version: MASTER branch
# Author:  Nicolas Hennion (aka) Nicolargo
#

# Execute a command as root (or sudo)
do_with_root() {
    # already root? "Just do it" (tm).
    if [[ `whoami` = 'root' ]]; then
        $@
    elif [[ -x /bin/sudo || -x /usr/bin/sudo ]]; then
        echo "sudo $*"
        sudo -H $@
    else
        echo "Glances requires root privileges to install."
        echo "Please run this script as root."
        exit 1
    fi
}

# Detect distribution name
if [[ `which lsb_release 2>/dev/null` ]]; then
    # lsb_release available
    distrib_name=`lsb_release -is`
elif [[ `which sw_vers 2>/dev/null` ]]; then
    # sw_vers available (for Mac OS X)
    distrib_name=`sw_vers -productName`
else
    # try other method...
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
if [[ $distrib_name == "ubuntu" || $distrib_name == "LinuxMint" || $distrib_name == "debian" || $distrib_name == "Raspbian" || $distrib_name == "neon" || $distrib_name == "elementary" ]]; then
    # Ubuntu/Debian variants

    # Set non interactive mode
    set -eo pipefail
    export DEBIAN_FRONTEND=noninteractive

    # Make sure the package repository is up to date
    #do_with_root apt-get -y update

    # Install prerequirements
    do_with_root apt-get install -y python-pip python-dev python-docker gcc lm-sensors wireless-tools

elif [[ $distrib_name == "redhat" ||  $distrib_name == "RedHatEnterpriseServer" || $distrib_name == "centos" || $distrib_name == "fedora" || $distrib_name == "Scientific" ]]; then
    # Redhat/CentOS/Fedora/SL

    # Install prerequirements
    do_with_root yum -y install python-pip python-devel gcc lm_sensors wireless-tools

elif [[ $distrib_name == "oracle" ]]; then
    # Oracle EL 7, should work on 6 as well

    # Enable repo
    do_with_root yum -y install yum-utils
    do_with_root yum-config-manager --enablerepo ol`. /etc/os-release; echo $VERSION | cut -d. -f1`_software_collections

    # Install prerequirements
    do_with_root yum -y install python27-python-pip python27-python-devel gcc lm_sensors wireless-tools

    # Create glances script
    GLANCES_BIN=/usr/bin/glances
    echo "#!/bin/bash" > $GLANCES_BIN
    echo ". /opt/rh/python27/enable" >> $GLANCES_BIN
    echo "glances" >> $GLANCES_BIN
    chmod +x $GLANCES_BIN

    # Load Python27 env
    . /opt/rh/python27/enable

elif [[ $distrib_name == "arch" ]]; then
    # Arch support

    # Headers not needed for Arch, shipped with regular python packages
    do_with_root pacman -S python-pip lm_sensors wireless_tools --noconfirm

elif [[ $distrib_name == "SuSE" ]]; then

    zypper --non-interactive in python-pip python-devel gcc python-curses

elif [[ $distrib_name == "centminmod" ]]; then
    # /CentOS min based

    # Install prerequirements
    do_with_root yum -y install python-devel gcc lm_sensors wireless-tools
    do_with_root wget -O- https://bootstrap.pypa.io/get-pip.py | python && $(which pip) install -U pip && ln -s $(which pip) /usr/bin/pip

elif [[ $distrib_name == "arch" ]]; then
    # Arch support

    # Headers not needed for Arch, shipped with regular python packages
    do_with_root pacman -S python-pip lm_sensors wireless_tools --noconfirm

 elif [[ $distrib_name == "alpine" ]]; then
    # Arch support

    # Headers not needed for Arch, shipped with regular python packages
    do_with_root apk add py-pip python-dev linux-headers musl-dev lm_sensors wireless-tools

elif [[ $distrib_name == "Mac OS X" ]]; then
    # Mac OS X support

    echo "Install Command lines Tools for XCode on your system"
    do_with_root xcode-select --install
    echo "Install Homebrew on your system"
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    echo "Install Python on your system"
    do_with_root brew install python

else
    # Unsupported system
    echo "Sorry, GlancesAutoInstall script is not compliant with your system."
    echo "Please read: https://github.com/nicolargo/glances#installation"
    exit 1

fi

shopt -u nocasematch

echo "Install dependencies"

# Glances issue #922: Do not install PySensors (SENSORS)
DEPS="setuptools glances[action,batinfo,browser,cpuinfo,docker,export,folders,gpu,graph,ip,raid,snmp,web,wifi]"

# Install libs
# do_with_root pip install --upgrade pip
do_with_root pip install $DEPS

# Install or upgrade Glances from the Pipy repository
if [[ -x /usr/local/bin/glances || -x /usr/bin/glances ]]; then
    echo "Upgrade Glances and dependencies"
    # Upgrade libs
    do_with_root pip install --upgrade $DEPS
    do_with_root pip install --upgrade glances
else
    echo "Install Glances"
    # Install Glances
    do_with_root pip install glances
fi
