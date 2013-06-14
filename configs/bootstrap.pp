#
# Ubuntu specific
#
if $::operatingsystem == 'Ubuntu' {

  # Remove some unwanted packages
  package {[ 'whoopsie', 'landscape-common', 'ntpdate', 'tmux', 'ppp',
            'isc-dhcp-common', 'apport', 'pppconfig', 'pppoeconf',
            'wpasupplicant', 'byobu', 'popularity-contest',
            'netcat-openbsd', 'wireless-tools', 'nano' ]:
    ensure  => purged,
  }

  # Install some usefull tools
  package { ['unzip', 'secure-delete', 'pwgen' ]:
    ensure  => present,
  }

  # If vmware guest then also install open-vm-tools
  if $::virtual == 'vmware' {
    package {'open-vm-tools':
      ensure  => present,
    }
    # and enable timesync with the host
    exec {'timesync':
      command => 'vmware-toolbox-cmd timesync enable',
      onlyif  => 'vmware-toolbox-cmd timesync status | grep Disabled',
      require => Package['open-vm-tools'],
      path    => [ '/bin', '/usr/bin' ],
    }
  }

  # Disable IPv6
  augeas {'disable_ipv6':
    context => '/files/etc/sysctl.conf',
    changes => [
    'set net.ipv6.conf.all.disable_ipv6 1',
    'set net.ipv6.conf.default.disable_ipv6 1',
    'set net.ipv6.conf.lo.disable_ipv6 1',
    'set net.ipv6.conf.eth0.disable_ipv6 1',
    ],
  }

  # Enable some process privacy
  $rc_local_contents = '#!/bin/sh -e
#
# rc.local
#

# remount /proc with hidepid=2
mount -o remount,hidepid=2 /proc

exit 0
'
  file { '/etc/rc.local':
    content => $rc_local_contents,
    owner => root,
    group => root,
    mode  => '0700',
  }

  # webserver
  if $::hostname == 'discovery' {
    # install amp stack
    #
    # apache + php first
    package { ['libapache2-mod-php5']:
        ensure  => present,
    }

    package { ['php5-mysql', 'php5-gd', 'php5-mcrypt', 'mysql-server',
                'libssh2-php' ]:
      ensure  => present,
      require => Package['libapache2-mod-php5'],
    }
  }
} # End of: Ubuntu
