# ageto_zookeeper #

This is the AGETO ZooKeeper Puppet module. It provides ZooKeeper installation and configuration capabilities for AGETO.

```puppet
node 'zookeeper-01' inherits default {
  # ZooKeeper setup
  class {'ageto_zookeeper':
    myid => '1',
    cluster_nodes => {
      '1' => { 'server' => '10.1.1.1', 'serverPort' => '2888', 'leaderElectionPort' => '3888'},
      '2' => { 'server' => '10.1.1.2', 'serverPort' => '2888', 'leaderElectionPort' => '3888'},
      '3' => { 'server' => '10.1.1.3', 'serverPort' => '2888', 'leaderElectionPort' => '3888'} },
    version => '3.4.5'
  }
}
```

