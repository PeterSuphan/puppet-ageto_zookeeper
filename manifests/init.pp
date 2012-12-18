# Class: ageto_zookeeper
#
# AGETO ZooKeeper management via Puppet
#
# Parameters:
#   parent_dir
#   user
#   group
#   version
#   zookeeper_home
#   zookeeper_log_dir
#   zookeeper_myid
#
# Actions:
#   create zookeeper users
#   deploy zookeeper
#   deploy zookeeper configuration
#
# Requires:
#  "repo" file share in Puppet to pull ZK from
#  see Modulefile
#
# Sample Usage:
#   include ageto_zookeeper
#
class ageto_zookeeper (
  $myid,
  $version,
  $cluster_nodes,
  $parent_dir     = $ageto_zookeeper::defaults::parent_dir,
  $home           = $ageto_zookeeper::defaults::home,
  $user           = $ageto_zookeeper::defaults::user,
  $group          = $ageto_zookeeper::defaults::group,
  $datastore      = $ageto_zookeeper::defaults::datastore,
  $datastore_logs = $ageto_zookeeper::defaults::datastore_logs,
  $log_dir        = $ageto_zookeeper::defaults::log_dir) inherits ageto_zookeeper::defaults {
  #
  class { 'ageto_zookeeper::create_user':
    parent_dir => $parent_dir,
    user       => $user,
    group      => $group
  }

  class { 'ageto_zookeeper::deploy':
    version        => $version,
    parent_dir     => $parent_dir,
    home           => $home,
    user           => $user,
    group          => $group,
    datastore      => $datastore,
    datastore_logs => $datastore_logs,
    log_dir        => $log_dir
  }

  class { 'ageto_zookeeper::deploy_configuration':
    myid           => $myid,
    cluster_nodes  => $cluster_nodes,
    home           => $home,
    user           => $user,
    group          => $group,
    datastore      => $datastore,
    datastore_logs => $datastore_logs,
    log_dir        => $log_dir
  }

  class { 'ageto_zookeeper::deploy_service':
    home           => $home,
    user           => $user,
    group          => $group,
    datastore      => $datastore,
    datastore_logs => $datastore_logs,
    log_dir        => $log_dir
  }
}

class ageto_zookeeper::create_user (
  $parent_dir = $ageto_zookeeper::defaults::parent_dir,
  $user       = $ageto_zookeeper::defaults::user,
  $group      = $ageto_zookeeper::defaults::group) inherits ageto_zookeeper::defaults {
  #
  # create system group
  group { $group:
    ensure => present,
    system => true,
  }

  #
  # create system user
  user { $user:
    comment => 'ZooKeeper System User',
    ensure  => present,
    home    => $parent_dir,
    gid     => $group,
    shell   => '/bin/false',
    system  => true,
    require => Group[$group],
  }
}

class ageto_zookeeper::deploy (
  $version,
  $parent_dir     = $ageto_zookeeper::defaults::parent_dir,
  $home           = $ageto_zookeeper::defaults::home,
  $user           = $ageto_zookeeper::defaults::user,
  $group          = $ageto_zookeeper::defaults::group,
  $datastore      = $ageto_zookeeper::defaults::datastore,
  $datastore_logs = $ageto_zookeeper::defaults::datastore_logs,
  $log_dir        = $ageto_zookeeper::defaults::log_dir,
  $pid_dir        = $ageto_zookeeper::defaults::pid_dir) inherits ageto_zookeeper::defaults {
  #
  # mandatory parameters
  if !$version {
    fail("Please specify parameter 'version'!")
  }

  # create parent directory
  file { $parent_dir:
    path   => $parent_dir,
    owner  => 'root',
    group  => 'root',
    mode   => 644,
    ensure => directory,
    backup => false,
  }

  # pull tar file from a "repo" file share
  file { "zookeeper-${version}.tar.gz":
    path   => "${parent_dir}/zookeeper-${version}.tar.gz",
    source => "puppet:///files/zookeeper/zookeeper-${version}.tar.gz",
    owner  => $user,
    group  => $group,
    backup => false,
  }

  # extract tar
  exec { "zookeeper_untar":
    command => "tar xzf zookeeper-${version}.tar.gz;",
    cwd     => $parent_dir,
    require => File["zookeeper-${version}.tar.gz"],
    creates => "${parent_dir}/zookeeper-${version}",
  }

  # fix ownership
  file { "zookeeper-reown-build":
    path    => "${parent_dir}/zookeeper-${version}",
    recurse => true,
    owner   => $user,
    group   => $group,
    require => Exec["zookeeper_untar"],
    backup  => false,
  }

  # symlink home dir to untarred zookeeper dir
  file { "${home}":
    target  => "${parent_dir}/zookeeper-${version}",
    ensure  => symlink,
    require => File["zookeeper-reown-build"],
    owner   => $user,
    group   => $group,
    backup  => false,
  }

  # create logs directory
  file { "zookeeper_log_folder":
    path   => $log_dir,
    owner  => $user,
    group  => $group,
    mode   => 644,
    ensure => directory,
    backup => false,
  }

  # create pid directory
  file { 'zookeeper_pid_dir':
    path   => $pid_dir,
    owner  => $user,
    group  => $group,
    mode   => 644,
    ensure => directory,
    backup => false,
  }

  # create data store
  file { "zookeeper_datastore":
    path   => $datastore,
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => 644,
    backup => false,
  }

  # create data store for transaction logs
  file { "zookeeper_datastore_logs":
    path   => $datastore_logs,
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => 644,
    backup => false,
  }

  # create tools directory
  file { "zookeeper_tools_folder":
    path   => "${parent_dir}/tools",
    owner  => $user,
    group  => $group,
    mode   => 644,
    ensure => directory,
    backup => false,
  }

  # push helpers to tools directory
  file { 'zktop':
    path   => "${parent_dir}/tools/zktop.py",
    source => 'puppet:///modules/ageto_zookeeper/tools/zktop.py',
    owner  => $user,
    group  => $group,
    mode   => 755,
    require => File["zookeeper_tools_folder"],
    backup => false,
  }
}

# deploy the zookeeper configuration
class ageto_zookeeper::deploy_configuration (
  $myid,
  $cluster_nodes,
  $home           = $ageto_zookeeper::defaults::home,
  $user           = $ageto_zookeeper::defaults::user,
  $group          = $ageto_zookeeper::defaults::group,
  $datastore      = $ageto_zookeeper::defaults::datastore,
  $datastore_logs = $ageto_zookeeper::defaults::datastore_logs,
  $log_dir        = $ageto_zookeeper::defaults::log_dir,
  $pid_dir        = $ageto_zookeeper::defaults::pid_dir) inherits ageto_zookeeper::defaults {
  #
  # mandatory parameters
  if !$myid {
    fail("Please specify parameter 'myid'!")
  }

  # create the myid file
  file { 'zookeeper_datastore_myid':
    path    => "${datastore}/myid",
    ensure  => file,
    content => $myid,
    owner   => $user,
    group   => $group,
    mode    => 644,
    require => File["zookeeper_datastore"],
    backup  => false,
  }

  # ZooKeeper configuration file
  #
  # requires a global zookeeper cluster definition in the nodes section
  # 'key' is the server id (aka. 'myid')
  #
  #   $cluster_nodes = {
  #     '1' => { 'server' => 'node1.some.domain.com', 'serverPort' => '2888', 'leaderElectionPort' => '3888'},
  #     '2' => { 'server' => 'node2.another.domain.com', 'serverPort' => '2888', 'leaderElectionPort' => '3888' },
  #     '3' => { 'server' => 'node3.some.domain.com', 'serverPort' => '2888', 'leaderElectionPort' => '3888'}
  #   }
  #
  file { 'conf/zoo.cfg':
    path    => "${home}/conf/zoo.cfg",
    owner   => $user,
    group   => $group,
    mode    => 644,
    content => template('ageto_zookeeper/conf/zoo.cfg.erb'),
    require => File[$home],
  }

  # additional environment variables
  file { 'zookeeper_java.env':
    path    => "${home}/conf/java.env",
    owner   => $user,
    group   => $group,
    mode    => 644,
    content => template('ageto_zookeeper/conf/java.env.erb'),
    require => File[$home],
  }

  # the log4j configuration
  file { 'zookeeper_log4j':
    path    => "${home}/conf/log4j.properties",
    owner   => $user,
    group   => $group,
    mode    => 644,
    content => template('ageto_zookeeper/conf/log4j.properties.erb'),
    require => File[$home],
  }
}

class ageto_zookeeper::deploy_service (
  $home           = $ageto_zookeeper::defaults::home,
  $user           = $ageto_zookeeper::defaults::user,
  $group          = $ageto_zookeeper::defaults::group,
  $datastore      = $ageto_zookeeper::defaults::datastore,
  $datastore_logs = $ageto_zookeeper::defaults::datastore_logs,
  $log_dir        = $ageto_zookeeper::defaults::log_dir,
  $pid_dir        = $ageto_zookeeper::defaults::pid_dir) inherits ageto_zookeeper::defaults {
  #
  # init script location
  $init_d_path     = $operatingsystem ? {
    Darwin  => "/usr/bin/zookeeper_service",
    default => "/etc/init.d/zookeeper",
  }
  # init script template
  $init_d_template = $operatingsystem ? {
    Darwin  => 'ageto_zookeeper/service/zookeeper_service_darwin.erb',
    /(?i-mx:ubuntu|debian)/        => 'ageto_zookeeper/service/zookeeper_service_debian.erb',
    /(?i-mx:centos|fedora|redhat)/ => 'ageto_zookeeper/service/zookeeper_service_redhat.erb',
    default => fail("No Init script template for ${operatingsystem}!"),
  }

  file { 'zookeeper_init_script':
    path    => $init_d_path,
    content => template($init_d_template),
    ensure  => file,
    owner  => 'root',
    group  => 'root',
    mode    => 755
  }
}

class ageto_zookeeper::defaults {
  $user           = 'zookeeper'
  $group          = 'zookeeper'

  $parent_dir     = '/srv/zookeeper'
  $home           = '/srv/zookeeper/current'

  $log_dir        = $operatingsystem ? {
    Darwin  => "/Users/$user/Library/Logs/zookeeper/",
    default => "/var/log/zookeeper",
  }
  $pid_dir      = '/var/run/zookeeper'

  $datastore      = '/srv/zookeeper/zkdata'
  $datastore_logs = '/srv/zookeeper/zklogs'
}
