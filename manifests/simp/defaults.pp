# Class: elasticsearch::simp::defaults
#
# This class is just for storing default option hashes so the the main
# classes are cleaner.
#
# Items are called from elasticsearch::simp
#
class elasticsearch::simp::defaults {

  if array_size($::elasticsearch::simp::unicast_hosts) < 3 {
    $min_master_nodes = '1'
  }
  else {
    $min_master_nodes = $::elasticsearch::simp::min_master_nodes
  }

  if empty($::elasticsearch::simp::service_settings['es_heap_size']) {
    $mem_bytes = to_bytes($::memorysize)

    if $mem_bytes < 4294967296 {
      $es_heap_size = ( $mem_bytes / 2 )
    }
    else {
      $es_heap_size = (( $mem_bytes / 2 ) + 2147483648 )
    }
  }

  $service_settings = {
    'ES_USER'      => 'elasticsearch',
    'ES_GROUP'     => 'elasticsearch',
    # The amount of memory that ES should allocate on startup.
    #   Default: 50% of Memory + 2G. If < 4G is present, just 50% of
    #   mem.
    'ES_HEAP_SIZE' => $es_heap_size
  }

  $base_config = {
    'cluster'     => {
      'name'                => $::elasticsearch::simp::cluster_name
    },
    'node'        => {
      'name'                => $::elasticsearch::simp::node_name
    },
    'index'       => {
      'number_of_replicas'  => $::elasticsearch::simp::replicas,
      'number_of_shards'    => $::elasticsearch::simp::shards
    },
    'network'     => {
      'bind_host' => $::elasticsearch::simp::bind_host
    },
    'http'        => {
      'bind_host' => $::elasticsearch::simp::http_bind_host,
      'port'      => $::elasticsearch::simp::http_port
    },
    'path'   => {
      'logs' => '/var/log/elasticsearch',
      'data' => $::elasticsearch::simp::data_dir
    },
    'discovery'                => {
      'zen'                    => {
        'minimum_master_nodes' => $min_master_nodes,
        'ping'                 => {
          'multicast'          => {
            'enabled'          => false
          },
          'unicast' => {
            'hosts' => $::elasticsearch::simp::unicast_hosts
          }
        }
      }
    }
  }
}
