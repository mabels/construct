require 'logger'

require 'fileutils'
require 'ostruct'

require 'ipaddress.rb'


module Construct

  @logger = Logger.new(STDOUT)
  @logger.level = Logger::DEBUG
  if !IPAddress::IPv6.instance_methods.include?(:rev_domains)
    @logger.fatal "you need the right ipaddress version from https://github.com/mabels/ipaddress" 
  end
  def self.logger
    @logger 
  end
  # ugly but i need the logger during initialization
  require 'construct/util.rb'
  require 'construct/addresses.rb'
  require 'construct/bgps.rb'
  require 'construct/users.rb'
  require 'construct/firewall.rb'
  require 'construct/flavour/delegates.rb'
  require 'construct/hosts.rb'
  require 'construct/interfaces.rb'
  require 'construct/ipsecs.rb'
  require 'construct/templates.rb'
  require 'construct/vlans.rb'
  require 'construct/flavour/flavour.rb'

  require 'construct/flavour/dlink-dgs15xx/flavour_dlink_dgs15xx.rb'
  require 'construct/flavour/graphviz/graphviz.rb'
  require 'construct/flavour/mikrotik/flavour_mikrotik.rb'
  require 'construct/flavour/ubuntu/flavour_ubuntu.rb'

  def self.produce
    Construct::Hosts.build_config()
    Construct::Interfaces.build_config()
    Construct::Ipsecs.build_config()
    Construct::Bgps.build_config()
    Construct::Hosts.commit()
  end

end