module Puppet::Parser::Functions

  newfunction(:es_iptables_format, :type => :rvalue, :doc => <<-'ENDHEREDOC') do |args|
    Format a passed Array of ip/host:port combinations into an appropriate iptables rule.
    This is very much ElasticSearch specific.

    ENDHEREDOC

    unless args.length == 1
      raise Puppet::ParseError, ("es_iptables_format(): wrong number of arguments '#{args.length}'; must be 1)")
    end
    unless args[0].is_a?(Array) or args[0].is_a?(String)
      raise Puppet::ParseError, "es_iptables_format(): expects the argument to be an array or string, got #{args[0].inspect} which is of type #{args[0].class}"
    end

    es_hosts = Array(args[0])

    iptables_rules = []

    es_hosts.each do |es_host|
      es_host,es_port = es_host.split(':')
      if not es_port then
        es_host,es_port = es_host.split('[')
        es_port = es_port.gsub('-',':')
      end

      if not es_port or es_port !~ /^\d+$/ then
        raise Puppet::ParseError, "es_iptables_format(): '#{es_port}' is not a valid port."
      end

      function_validate_net_list(Array(es_host))

      iptables_rules << "-s #{es_host} -p tcp -m state --state NEW -m tcp -m multiport --dports #{es_port} -j ACCEPT"
    end

    # We should never hit this but, if we do, we need to know.
    iptables_rules.empty? and raise Puppet::ParseError, "es_iptables_format(): Error, iptables rules result set empty!"

    iptables_rules.join("\n")
  end

end
