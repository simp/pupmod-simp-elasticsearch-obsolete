# == Class: elasticsearch::simp::apache::defaults
#
# This class exists to provide some default settings that can be merged into
# other hashes within the elasticsearch::simp::apache class
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class elasticsearch::simp::apache::defaults {
  $method_acl = {
    'method' => {
      'file' => {
        'enable'    => false,
        'user_file' => '/etc/httpd/conf.d/elasticsearch/.htdigest'
      },
      'ldap'    => {
        'enable'    => false,
        'url'         => hiera('ldap::uri'),
        'security'    => 'STARTTLS',
        'binddn'      => hiera('ldap::bind_dn'),
        'bindpw'      => hiera('ldap::bind_pw'),
        'search'      => inline_template('ou=People,<%= scope.function_hiera(["ldap::base_dn"]) %>'),
        'posix_group' => true
      }
    },
    'limits'  => {
      'defaults'  => [ 'GET', 'POST', 'PUT' ],
      'hosts'  => {
        '127.0.0.1' => 'defaults',
        "$::fqdn"   => 'defaults'
      }
    }
  }
}
