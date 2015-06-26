# == Class: elasticsearch::simp
#
# This class extends the electrical-elasticsearch module in the configuration
# settings recommended for SIMP systems.
#
# Please use the portions that make sense for your environment.
#
# The classes are separated in such a way as to be usable individually where
# possible.
#
# At this time, it is NOT possible to encrypt data across the ES transport
# mechanism. The http interface is optionally fronted with Apache and encrypted
# that way.
#
# We are planning to move to add IPSec support in the future so that the
# transport layer can be optionally protected internally.
#
# Currently, an IPTables rule is created for each host that you add to your
# unicast hosts list. We will be moving to use ipset in the future for
# optimization.
#
# ES Tuning settings were taken from
# http://edgeofsanity.net/article/2012/12/26/elasticsearch-for-logging.html
#
# == Parameters
#
# [*cluster_name*]
#   String: The name of the cluster that this node will be joining.
#   Required
#
# [*replicas*]
#   Integer: The number of replicas for the ES cluster.
#   Default: 1
#
# [*shards*]
#   Integer: The number of shards for the ES cluster.
#   Default: 5
#
# [*node_name*]
#   String: An arbitrary, unique name fo this node.
#   Default: $::fqdn
#
# [*bind_host*]
#   IP Address: The IP address to which to bind the cluster communications
#   service.
#     * Do NOT set this to 127.0.0.1 unless you *really* know what you are
#     doing.
#   Default: $::ipaddress
#
# [*http_bind_host*]
#   IP Address: The IP address to which to bind the http service.
#     * Do NOT set this to 127.0.0.1 unless you *really* know what you are
#       doing.
#   Default: $::ipaddress
#
# [*http_port*]
#   Integer:
#   This port will be exposed for http interactions into the ES engine.
#   This will *not* be exposed directly through iptables unless set to 9200.
#   9200 is the ES default so setting this to *anything else* means that you
#   want to proxy and to not expose this port to the world.
#   Default: 9199
#
# [*http_method_acl*]
#   Hash of ACL Options:
#    This controls the remote accesses allowed to ES.
#    This is quite complex, see elasticsearch::apache option 'method_acl' for
#    details.
#   Default: $elasticsearch::apache::method_acl
#
# [*https_client_nets*]
#   Array of IPs/host:
#   This is an array of IPs/hosts to allow to connect to the https service.
#   If you're using ES for LogStash, then all clients that should be able to
#   connect to this node in order to store data into ES should be allowed.
#   Default: '127.0.0.1'
#
# [*data_dir*]
#   Fully Qualified Path:
#     The path where the data should be stored.
#     You will need to create all parent directories, this module will not do
#     it for you.
#   Default: $data_dir = versioncmp(simp_version(),'5') ? { '-1' => '/srv/elasticsearch', default => '/var/elasticsearch' }
#
# [*min_master_nodes*]
#   Integer:
#     The number of master nodes that consitutes an operational cluster.
#     If fewer than 3 unicast hosts are specified below, this will default to
#     1.
#   Default: $unicast_hosts < 3 ? 1 : 2
#
# [*unicast_hosts*]
#   Array of host:port pairs.
#     We do not support multicast joining for security reasons. You must
#     specify all of your hosts.
#   Default: "${::hostname}:9300"
#   * It not recommended to change this default unless you have a different
#     hiera variable that you are using.
#
# [*service_settings*]
#   Hash: options that will be passed directly into
#     /etc/sysconfig/elasticsearch. Anything passed in via this hash
#     will be merged with the default hash below.
#   Default:
#     $::elasticsearch::simp::defaults::service_settings
#
# [*es_config*]
#   Hash: options as required by the 'elasticsearch' module.
#     If you specify your own hash, then it will be merged with the default.
#   Default:
#     $::elasticsearch::simp::defaults::base_config
#
# [*max_log_days*]
#   Type: Float
#   Default: '7'
#     The number of days of elasticsearch logs to keep on the system. Note:
#     This will *not* remove files by size so watch your cluster disk space in
#     /var/log.
#
# [*manage_httpd*]
#   String: One of true, false, 'conf'
#   Whether or not to manage the httpd configuration on this system.
#     * true  => Manage the entire web stack.
#     * false => Manage nothing.
#     * conf  => Just drop the configuration file into /etc/httpd/conf.d
#   Default: 'true'
#
# [*restart_on_change*]
#   Boolean:
#   Whether or not to restart on a configuration change.
#   Default: 'true'
#
# [*use_iptables*]
#   Boolean:
#   Whether or not to use iptables for ES connections. If set to 'false', then
#   this will simply add a rule allowing *anyone* to connect. This will not
#   actually disable IPTables completely.
#   For obvious reasons, it is suggested to leave this on.
#   Default: 'true'
#
# [*java_install*]
#   Boolean:
#     Whether or not to use puppet to install Java via this module.
#     Please don't use this if it will conflict with another module.
#     If the RPM worked properly, this would not be necessary and will
#     hopefully be fixed in the future.
#     NOTE: ES will *not* run without Java installed!
#   Default: false
#
# [*install_unix_utils*]
# Type: Boolean
# Default: true
#   Whether or not to install the es2unix package.
#
# == Examples
#
# * Set up an ES instance that will only run on this server.
# ** No entry added to the extdata directory
#
# class { 'elasticsearch::simp': cluster_name => 'single' }
#
# * Set up an ES instance that will act as part of a larger cluster.
# ** An entry in extdata must be set to the following:
# *** elasticsearch::simp,"<ip_address_one>","<ip_address_two>"
#
# class { 'elasticsearch::simp':
#   cluster_name        => 'multi',
#   number_of_replicas  => '2',
#   number_of_shards    => '8'
# }
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class elasticsearch::simp (
  $cluster_name,
  $node_name = $::fqdn,
  $replicas = '1',
  $shards = '5',
  $bind_host = $::ipaddress,
  $http_bind_host = '127.0.0.1',
  $http_port = '9199',
  $http_method_acl = {},
  $data_dir = versioncmp(simp_version(),'5') ? { '-1' => '/srv/elasticsearch', default => '/var/elasticsearch' },
  $min_master_nodes = '2',
  $unicast_hosts = "${::fqdn}:9300",
  $service_settings = {},
  $es_config = {},
  $max_log_days = '7',
  $max_locked_memory = '',
  $max_open_files = '',
  $manage_httpd = true,
  $https_client_nets = '127.0.0.1',
  $restart_on_change = true,
  $use_iptables = true,
  $java_install = false,
  $java_package = 'java-1.7.0',
  $install_unix_utils = true
) {
  include '::elasticsearch::simp::defaults'


  if !empty($es_config) {
    $l_config = deep_merge($::elasticsearch::simp::defaults::base_config,$es_config)
  }
  else {
    $l_config = $::elasticsearch::simp::defaults::base_config
  }

  # TODO: Figure out how to move this into a single include!
  class { 'elasticsearch':
    config            => $l_config,
    autoupgrade       => true,
    status            => 'running',
    service_settings  => deep_merge($service_settings,$::elasticsearch::simp::defaults::service_settings),
    restart_on_change => $restart_on_change,
    java_install      => $java_install,
    java_package      => $java_package
  }

  file { '/etc/cron.daily/elasticsearch_log_purge':
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => "#!/bin/sh
if [ -d /var/log/elasticsearch ]; then
  /bin/find /var/log/elasticsearch -type f -mtime +${max_log_days} -exec /bin/rm {} \\;
fi
"
  }

  # Correct the permissions on the ES templates directory
  file { '/etc/elasticsearch/templates_import':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { $l_config['path']['data']:
    ensure  => 'directory',
    owner   => 'elasticsearch',
    group   => 'elasticsearch',
    require => Package['elasticsearch']
  }

  # This is here due to some weird bug in ES that won't read /etc properly.
  file { '/usr/share/elasticsearch/config':
    ensure => 'symlink',
    target => '/etc/elasticsearch',
    force  => true
  }

  if $use_iptables {
    iptables_rule { 'elasticsearch_allow_cluster':
      first   => true,
      content => es_iptables_format($l_config['discovery']['zen']['ping']['unicast']['hosts']),
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch']
    }
  }
  else {
    iptables::add_tcp_stateful_listen{ 'elasticsearch_allow_cluster':
      client_nets => 'ALL',
      dports      => '9300',
      require     => Package['elasticsearch'],
      notify      => Service['elasticsearch']
    }
  }

  # Manage both apache and the config.
  if $manage_httpd {
    class { 'elasticsearch::simp::apache':
      proxyport  => $l_config['http']['port'],
      method_acl => $http_method_acl
    }
  }
  elsif $manage_httpd == 'conf' {
    class { 'elasticsearch::simp::apache':
      manage_httpd => false,
      proxyport    => $l_config['http']['port'],
      method_acl   => $http_method_acl
    }
  }
  # Otherwise, don't manage apache or the config.

  if $install_unix_utils {
    package { 'es2unix': ensure => 'latest' }
  }

  include 'pam::limits'

  pam::limits::add { 'es_heap_sizelock':
    domain => 'elasticsearch',
    type   => '-',
    item   => 'memlock',
    value  => 'unlimited',
    order  => '0',
    notify => Service['elasticsearch']
  }

  # Validation
  validate_integer($replicas)
  validate_integer($shards)
  validate_net_list($bind_host)
  validate_net_list($http_bind_host)
  validate_integer($http_port)
  validate_net_list($unicast_hosts,'^(any|ALL)$')
  validate_hash($es_config)
  validate_hash($service_settings)
  validate_re_array(keys($service_settings),'^[A-Z,_]+$')
  validate_float($max_log_days)
  validate_array_member($manage_httpd,[true,false,'conf'])
  validate_net_list($https_client_nets,'^(any|AlL)$')
  validate_bool_simp($restart_on_change)
  validate_bool_simp($java_install)
  validate_bool_simp($use_iptables)
  validate_bool($install_unix_utils)
}
