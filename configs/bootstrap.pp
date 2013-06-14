#
# Defines
#
define site($domain)  {

  user { $name:
    ensure  => present,
    gid   => 'www-data',
    home  => "/sites/${name}",
  }->
  file { [ "/sites/${name}", "/sites/${name}/www",
        "/sites/${name}/tmp", "/sites/${name}/backups" ]:
    ensure  => 'directory',
    owner   => $name,
    group   => 'www-data',
    mode    => '0770',
  }->
  apache::vhost { $domain:
    port          => '80',
    docroot       => "/sites/${name}/www",
#    directory     => [ { path => '/sites/${name}/www',
#                      options => ['SymLinksIfOwnerMatch'],
#                      allowOverride => ['All'] }],
    docroot_group => 'www-data',
    docroot_owner => $name,
  }
}

#
# Ubuntu specific
#

if $::operatingsystem == 'Ubuntu' {

  include concat::setup

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
    file { '/sites':
      ensure  => directory,
      owner   => 'root',
      group   => 'www-data',
      mode    => '0750',
    }

    # apache
    class { 'apache':
      default_vhost   => false,
    }

    apache::mod { 'rewrite': }

    site { 'alpha': domain  => 'alpha.dev', }
    site { 'beta': domain  => 'alpha.dev', }
#    package { ['libapache2-mod-php5']:
#        ensure  => present,
#    }
#
#    package { ['php5-mysql', 'php5-gd', 'php5-mcrypt', 'mysql-server',
#                'libssh2-php' ]:
#      ensure  => present,
#      require => Package['libapache2-mod-php5'],
#    }
  }
} # End of: Ubuntu
