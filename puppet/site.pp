#
# Defines
#
define site($ensure='present', $domain, $domainalias='', $password, $dbpassword) {

  if $ensure == 'present' {
    $dir_ensure = 'directory'
  } else {
    $dir_ensure = 'absent'
  }

  user { $name:
    ensure   => $ensure,
    gid      => 'www-data',
    home     => "/sites/${name}",
    comment  => "${name}",
    shell    => '/bin/false',
    password => $password,
  }->
  file { "/sites/${name}":
    ensure  => $dir_ensure,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0750',
    force   => true,
  }->
  file { [ "/sites/${name}/www",
        "/sites/${name}/tmp", "/sites/${name}/backups" ]:
    ensure  => $dir_ensure,
    owner   => $name,
    group   => 'www-data',
    mode    => '0750',
    force   => true,
  }->
  apache::vhost { $domain:
    ensure            => $ensure,
    port              => '80',
    docroot           => "/sites/${name}/www",
    serveraliases     => $domainalias,
    options           => ['SymLinksIfOwnerMatch', '-Indexes'],
    override          => ['All'],
    docroot_group     => 'www-data',
    docroot_owner     => $name,
    suphp_addhandler  => 'x-httpd-php',
    suphp_engine      => 'on',
    suphp_configpath  => '/etc/php5/apache2',
  }->
  mysql::db { $name:
    ensure   => $ensure,
    user     => $name,
    password => $dbpassword,
    host     => 'localhost',
    grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'ALTER',
                 'INDEX', 'DROP', 'LOCK TABLES'],
  }
}

#
# Ubuntu specific
#

if $::operatingsystem == 'Ubuntu' {

  include concat::setup

  # Remove some unwanted packages
  package {[ 'whoopsie', 'landscape-common', 'ntpdate', 'tmux', 'ppp',
            'apport', 'pppconfig', 'pppoeconf', 'wpasupplicant',
            'byobu', 'popularity-contest', 'netcat-openbsd',
            'wireless-tools', 'nano' ]:
    ensure  => purged,
  }

  # on non EC2 based hosts also remove these packages
  if $::virtual != 'xen' {
    package {[ 'isc-dhcp-common' ]:
      ensure  => purged,
    }
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
  $rc_local_content = '#!/bin/sh -e
#
# rc.local
#

# remount /proc with hidepid=2
mount -o remount,hidepid=2 /proc

exit 0
'
  file { '/etc/rc.local':
    content => $rc_local_content,
    owner => root,
    group => root,
    mode  => '0700',
  }

  # webserver
  if hiera('role') == 'web' {
    # sites directory
    file { '/sites':
      ensure  => directory,
      owner   => 'root',
      group   => 'www-data',
      mode    => '0750',
    }

    # apache
    class { 'apache':
      default_vhost     => false,
      default_mods      => false,
      purge_configs     => true,
      server_tokens     => 'Prod',
      server_signature  => 'Off',
    }
    # apache modules
    class { 'apache::mod::rewrite': }
    class { 'apache::mod::mime': }
    class { 'apache::mod::dir': }
    apache::mod { 'auth_basic': }
    apache::mod { 'authn_file': }
    apache::mod { 'authz_user': }

    # mysql
    class { '::mysql::server':
      remove_default_accounts   => true,
      require                   => Class['apache'],
    }->
    package { 'automysqlbackup':
      ensure    => present,
    }

    # php
    $suphp_conf_content = '
[global]
logfile=/var/log/suphp/suphp.log
loglevel=info
webserver_user=www-data
docroot=/var/www:${HOME}/www
allow_file_group_writeable=false
allow_file_others_writeable=false
allow_directory_group_writeable=false
allow_directory_others_writeable=false
check_vhost_docroot=true
errors_to_browser=false
env_path=/bin:/usr/bin
umask=0027
min_uid=1000
min_gid=33
[handlers]
application/x-httpd-suphp="php:/usr/bin/php-cgi"
x-suphp-cgi="execute:!self"
'

    class { 'apache::mod::suphp':
    }->
    file { '/etc/suphp/suphp.conf':
        content => $suphp_conf_content,
        owner   => root,
        group   => root,
        mode    => '0644',
        notify  => Service['httpd'],
    }->
    package { ['php5-mysql', 'php5-gd', 'php5-mcrypt', 'libssh2-php' ]:
      ensure  => present,
    }

    # ssh sftp
    $sshd_config_content = '
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 768
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin no
StrictModes yes
RSAAuthentication no
PubkeyAuthentication yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
PasswordAuthentication yes
ChallengeResponseAuthentication no
X11Forwarding no
GatewayPorts no
AllowTcpForwarding no
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*
Subsystem sftp internal-sftp
UsePAM yes
AllowGroups www-data sysadmin
# sftp only users www-data group
Match group www-data
  ChrootDirectory %h
  ForceCommand internal-sftp
  PasswordAuthentication yes
'
    file { '/etc/ssh/sshd_config':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0400',
      content => $sshd_config_content,
      notify  => Service['ssh'],
    }
    service { 'ssh':
      ensure  => running,
    }

    # create hosted accounts
    if hiera('sites') {
      $sites = hiera('sites')
      create_resources(site, $sites)
    }
  }
} # End of: Ubuntu
