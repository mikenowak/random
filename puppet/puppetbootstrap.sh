#!/bin/bash
#
# Script to bootstrap puppet on a freshly provisioned box
# currently supports only ubuntu and redhat.
#

# Redhat or Ubuntu?
if [ -r /etc/redhat-release ]; then
  OPERATINGSYSTEM="redhat"
  if [ -n "`grep 'release 6' /etc/redhat-release`" ]; then
    RELEASE="6"
  elif [ -n "`grep 'release 5' /etc/redhat-release`" ]; then
    RELEASE="5"
  else
    echo "This script is not designed for this release, exitting."
    exit 1
  fi

elif uname -v | grep Ubuntu >/dev/null; then
  OPERATINGSYSTEM="ubuntu"
  CODENAME="`grep DISTRIB_CODENAME /etc/lsb-release | awk -F= '{ print $2 }'`"
else
  echo "This script is not designed for this platform, exitting."
  exit 1
fi

#
# UBUNTU LOGIC
#
if [ "$OPERATINGSYSTEM" == "ubuntu" ]; then
  # install puppetlabs repo if not installed
  if [ -z "`dpkg-query -W --showformat='\${Status}\n' puppetlabs-release | grep 'install ok installed'`" ]; then
    wget -qO "/tmp/puppetlabs-release-${CODENAME}.deb" http://apt.puppetlabs.com/puppetlabs-release-${CODENAME}.deb
    dpkg -i /tmp/puppetlabs-release-${CODENAME}.deb
  fi

  # make sure the system is upto date
  apt-get -qq update
  apt-get -y dist-upgrade
  apt-get autoremove

  # install puppet and git
  apt-get -y install puppet git
fi

#
# REDHAT LOGIC
#
if [ "$OPERATINGSYSTEM" == "redhat" ]; then
  # install puppetlabs repo if not installed
  if [ -z "`rpm -qa | grep puppetlabs-release`" ]; then
    rpm -ivh http://yum.puppetlabs.com/el/${RELEASE}/products/x86_64/puppetlabs-release-${RELEASE}-7.noarch.rpm
  fi

  # make sure the system is upto date
  yum clean all
  yum -y update

  # install puppet and git
  yum -y install puppet git

fi

#
# COMMON LOGIC
#

if [ ! -d /etc/puppet/manifests ]; then mkdir /etc/puppet/manifests; fi
if [ ! -d /etc/puppet/modules ]; then mkdir /etc/puppet/modules; fi
if [ ! -d /etc/puppet/hieradata ]; then mkdir /etc/puppet/hieradata; fi

# Install some puppet modules
cd /etc/puppet/modules
puppet module install puppetlabs-firewall
puppet module install puppetlabs-stdlib
puppet module install puppetlabs-concat
#puppet module install puppetlabs-apache
git clone https://github.com/puppetlabs/puppetlabs-apache.git apache
puppet module install puppetlabs-mysql

# And some configs
wget -O /etc/puppet/manifests/site.pp https://raw.github.com/mikenowak/random/master/puppet/site.pp
wget -O /etc/puppet/hiera.yaml https://raw.github.com/mikenowak/random/master/puppet/hiera.yaml
wget -O /usr/local/bin/siteadm https://raw.github.com/mikenowak/random/master/puppet/siteadm && chmod +x /usr/local/bin/siteadm
wget -O /etc/puppet/hieradata/$HOSTNAME.yaml https://raw.github.com/mikenowak/random/master/puppet/$HOSTNAME.yaml

puppet apply --show_diff --verbose /etc/puppet/manifests/site.pp

rm $0

init 6
