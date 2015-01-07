module Construqt
  class Interfaces
    def initialize(region)
      @region = region
      @interfaces = {}
    end

    def setup_template(iface)
      iface.template.vlans.each do |vlan|

        vname = vlan.description
        to_add_iface = iface.host.interfaces[vname]
        unless to_add_iface
          to_add_iface = add_vlan(iface.host, vname, vlan.to_h.inject({}){|r,(k,v)| r[k.to_s]=v; r })
        end

        #puts ">>>>>#{iface.name}"
        to_add_iface.interfaces << iface
      end
    end

    def add_device(host, dev_name, cfg)
      throw "Host not found:#{dev_name}" unless host
      binding.pry if host.interfaces[dev_name]
      throw "Interface is duplicated:#{host.name}:#{dev_name}" if host.interfaces[dev_name]
      throw "invalid name #{dev_name}" unless dev_name.match(/^[A-Za-z0-9\-\.]+$/)
      if match=/^.*[^\d](\d+)$/.match(dev_name)
        cfg['number'] ||= match[1].to_i
      end

      cfg['host'] = host
      cfg['mtu'] ||= 1500
      #binding.pry if host && host.name == "ct-iar1-ham"
      #    binding.pry
      cfg['clazz'] ||= "device"
      cfg['address'] ||= nil
      cfg['firewalls'] ||= []
      cfg['firewalls'] = cfg['firewalls'].map{|i| i.kind_of?(String) ? Construqt::Firewalls.find(i) : i }
      (dev_name, iface) = Construqt::Tags.add(dev_name) { |name| host.flavour.create_interface(name, cfg) }
      #    iface.clazz.attach = iface
      host.interfaces[dev_name] = iface
      host.interfaces[dev_name].address.interface = host.interfaces[dev_name] if host.interfaces[dev_name].address
      setup_template(iface) if iface.template
      @interfaces[dev_name] ||= []
      @interfaces[dev_name] << iface
      host.interfaces[dev_name]
    end

#    def add_template(host, name, cfg)
#     cfg['clazz'] = "template"
#    cfg['host'] = host
#   cfg['name'] = name
#      self.add_device(host,name, cfg)
#    end

    def add_openvpn(host, name, cfg)
      cfg['clazz'] = "opvn"
      cfg['ipv6'] ||= nil
      cfg['ipv4'] ||= nil
      dev = add_device(host, name, cfg)
      dev.address.interface = host.interfaces[name] if dev.address
      dev.network.name = "#{name}-#{host.name}"
      dev
    end

    def add_gre(host, name, cfg)
      throw "we need an address on this cfg #{cfg.inspect}" unless cfg['address']
      cfg['clazz'] = "gre"
      cfg['local'] ||= nil
      cfg['remote'] ||= nil
      dev = add_device(host, name, cfg)
      dev.address.interface = host.interfaces[name] if dev.address
      dev
    end

    def add_vlan(host, name, cfg)
      unless cfg["vlan_id"].to_s.match(/^[0-9]+$/) && 1 <= cfg["vlan_id"].to_i && cfg["vlan_id"].to_i < 4096
        throw "vlan_id must be set on vlan with name #{name}"
      end
      cfg = cfg.clone
      interfaces = cfg['interfaces'] || []
      interfaces << cfg['interface'] if cfg['interface']
      cfg.delete('interface')
      cfg['interfaces'] = interfaces
      #    throw "we need an interface #{cfg['interfaces']}" if cfg['interfaces'].empty?
      cfg['clazz'] = "vlan"
      dev = add_device(host, name, cfg)
      dev.address.interface = host.interfaces[name] if dev.address
      dev
    end

    def add_bond(host, name, cfg)
      cfg['interfaces'].each do |interface|
        throw "interface not one same host:#{interface.host.name}:#{host.name}" unless host.name == interface.host.name
      end

      cfg['clazz'] = "bond"
      dev = add_device(host, name, cfg)
      dev.address.interface = host.interfaces[name] if dev.address
      dev
    end

    def add_vrrp(name, cfg)
      nets = {}
      cfg['address'].ips.each do |adr|
        if adr.ipv4? && adr.prefix != 32
          unless cfg['address'].routes.find{ |rt| adr.include?(rt.via) }
            throw "only host ip's are allowed #{adr.to_s} with prefix != 32 or route"
          end
        end
        throw "only host ip's are allowed #{adr.to_s}" if adr.ipv6? && adr.prefix != 128
        nets[adr.network.to_s] = true
      end

      cfg['interfaces'].each do |interface|
        throw "interface need priority #{interface.name}" unless interface.priority
        throw "interface not found:#{name}" unless interface
        cfg['clazz'] = "vrrp"
        cfg['interface'] = interface
        throw "vrrp interface does not have within the same network" if nets.length == interface.address.ips.select { |adr| nets[adr.network.to_s] }.length
        dev = add_device(interface.host, name, cfg)
#        interface.firewalls.push(*(dev.firewalls || []))
        interface.vrrp = dev
        dev.address.interface = nil
        dev.address.host = nil
        dev.address.name = name
      end
    end

    def add_bridge(host, name, cfg)
      #cfg['interfaces'] = []
      cfg['interfaces'].each do |interface|
        throw "interface not one same host:#{interface.host.name}:#{host.name}" unless host.name == interface.host.name
      end

      cfg['clazz'] = "bridge"
      dev = add_device(host, name, cfg)
      dev.address.interface = host.interfaces[name] if dev.address
      dev
    end

    def _find(host_or_name, iface_name)
      if host_or_name.kind_of?(String)
        host = @region.hosts.find(host_or_name)
        return [nil, nil] unless host
      else
        host = host_or_name
      end
      iface = host.interfaces[iface_name]
      return [host, nil] unless iface
      [host, iface]
    end

    def find!(host_or_name, iface_name)
      (host, iface) = _find(host_or_name, iface_name)
      return nil if host.nil? || iface.nil?
      iface
    end

    def find(host_or_name, iface_name)
      (host, iface) = _find(host_or_name, iface_name)
      throw "host not found #{host_or_name}" if host.nil?
      throw "interface not found for #{iface_name}:#{host.name}" if iface.nil?
      iface
    end

    def find_by_name(iface_name)
      ret = @interfaces[iface_name]
      throw "interfaces with name #{iface_name} not found" if ret.nil? or ret.empty?
      ret
    end

    def build_config(hosts = nil)
      (hosts||Hosts.get_hosts).each do |host|
        by_clazz = {}
        host.interfaces.values.each do |interface|
          #throw "class less interface #{interface.inspect}" unless interface.clazz
          #throw "no clazz defined in interface #{interface.clazz}" unless interface.clazz.name
          name = interface.clazz # .name[interface.clazz.name.rindex(':')+1..-1].downcase
          #puts "<<<<<<< #{name}"
          by_clazz[name] ||= []
          by_clazz[name] << interface
        end

        #binding.pry
        ["host", "device", "vlan", "bond", "bridge", "vrrp", "gre", "bgp", "opvn", "ipsec"].each do |key|
          next unless by_clazz[key]
          by_clazz[key].each do |interface|
            #Construqt.logger.debug "Interface:build_config:#{interface.name}:#{interface.class.name}:#{interface.ident}"
            interface.build_config(host, interface)
          end
        end
      end
    end
  end
end
