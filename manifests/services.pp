# Class: services
#
# AGETO ZooKeeper services management via Puppet
#
# Parameters:
#   N/A
# Actions:
#   deploy /etc/init.d service for zookeeper
#   start it and set it as enabled
# Requires:
#  zookeeper
# Sample Usage:
#  include services::zookeeper
#
class services {
  # Puppet auto-lookup
}

class services::zookeeper (
  $home           = $ageto_zookeeper::defaults::home,
  $user           = $ageto_zookeeper::defaults::user,
  $group          = $ageto_zookeeper::defaults::group,
  $datastore      = $ageto_zookeeper::defaults::datastore,
  $datastore_logs = $ageto_zookeeper::defaults::datastore_logs,
  $log_dir        = $ageto_zookeeper::defaults::log_dir) inherits ageto_zookeeper::defaults {
  if $operatingsystem != Darwin {
    service { 'zookeeper':
      ensure    => running,
      enable    => true,
      hasstatus => false,
      pattern   => "QuorumPeerMain",
      require   => [
        File['zookeeper_init_script'],
        File[$home]]
    }
  } else {
    exec { 'zookeeper_service':
      command => "zookeper_service start",
      cwd     => "/usr/bin/",
      require => [
        File['zookeeper_init_script'],
        File[$home]]
    }
  }
}

