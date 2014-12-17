
module Construqt
  module Ipsecs
    class Ipsec < OpenStruct
      def initialize(cfg)
        super(cfg)
      end

      def build_config()
        self.left.build_config(nil, nil)
        self.right.build_config(nil, nil)
      end

      def ident
        self.left.ident
      end
    end

    @ipsecs = {}
    def self.add_connection(cfg, id, to_id, iname)
      throw "my not found #{cfg[id].inspect}" unless cfg[id]['my']
      throw "host not found #{cfg[id].inspect}" unless cfg[id]['host']
      throw "remote not found #{cfg[id].inspect}" unless cfg[id]['remote']
      cfg[id]['other'] = nil
      cfg[id]['cfg'] = nil
      cfg[id]['my'].host = cfg[id]['host']
      cfg[id]['my'].name = "#{iname}-#{cfg[id]['host'].name}"
      cfg[id]['interface'] = nil
      cfg[id] = cfg[id]['host'].flavour.create_ipsec(cfg[id])
    end

    def self.connection(name, cfg)
      #    binding.pry
      add_connection(cfg, 'left', 'right', Util.add_gre_prefix(cfg['right']['host'].name))
      add_connection(cfg, 'right', 'left', Util.add_gre_prefix(cfg['left'].host.name))
      cfg['name'] = name
      cfg['transport_family'] ||= Construqt::Addresses::IPV6
      cfg = @ipsecs[name] = Ipsec.new(cfg)
      cfg.left.other = cfg.right
      cfg.left.cfg = cfg
      cfg.right.other = cfg.left
      cfg.right.cfg = cfg

      cfg.left.host.add_ipsec(cfg)
      cfg.right.host.add_ipsec(cfg)

      #puts "-------- #{cfg.left.my.host.name} - #{cfg.right.my.host.name}"
      cfg.left.interface = cfg.left.my.host.region.interfaces.add_gre(cfg.left.my.host, cfg.left.other.host.name,
                                                                      "address" => cfg.left.my,
                                                                      "local" => cfg.left.remote,
                                                                      "remote" => cfg.right.remote,
                                                                      "ipsec" => cfg
                                                                     )
      cfg.right.interface = cfg.left.my.host.region.interfaces.add_gre(cfg.right.my.host, cfg.right.other.host.name,
                                                                       "address" => cfg.right.my,
                                                                       "local" => cfg.right.remote,
                                                                       "remote" => cfg.left.remote,
                                                                       "ipsec" => cfg
                                                                      )
      cfg
    end

    def self.build_config()
      hosts = {}
      @ipsecs.values.each do |ipsec|
        hosts[ipsec.left.host.object_id] ||= ipsec.left.host
        hosts[ipsec.right.host.object_id] ||= ipsec.right.host
      end
      #binding.pry
      hosts.values.each do |host|
        host.flavour.ipsec.header(host) if host.flavour.ipsec.respond_to?(:header)
      end
      @ipsecs.each do |name, ipsec|
        ipsec.build_config()
      end
    end
  end
end
