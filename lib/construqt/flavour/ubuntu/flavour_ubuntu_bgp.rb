module Construqt
  module Flavour
    module Ubuntu

      class Bgp
        attr_accessor :delegate, :other, :cfg
        attr_reader :host, :my, :as, :filter
        def initialize(cfg)
          self.other = cfg['other']
          self.cfg = cfg['cfg']
          @host = cfg['host']
          @my = cfg['my']
          @as = cfg['as']
          @filter = cfg['filter']
        end

        def self.header(host)
          return if host.bgps.empty?
          # binding.pry
          bird_v4 = self.header_bird(host, OpenStruct.new(:net_clazz => lambda {|o|
            (o.kind_of?(IPAddress::IPv4)||o.kind_of?(Construqt::Addresses::CqIpAddress)) && o.ipv4?
          },
                                                          :filter => lambda {|ip| ip.ipv4? }))
          host.result.add(self, bird_v4, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::BGP), "etc", "bird", "bird.conf")
          bird_v6 = self.header_bird(host, OpenStruct.new(:net_clazz => lambda {|o|
            (o.kind_of?(IPAddress::IPv6)||o.kind_of?(Construqt::Addresses::CqIpAddress)) && o.ipv6?
          },
                                                          :filter => lambda {|ip| ip.ipv6? }))
          host.result.add(self, bird_v6, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::BGP), "etc", "bird", "bird6.conf")
        end

        def self.header_bird(host, mode)
          #binding.pry
          ret = <<BGP
log syslog { debug, trace, info, remote, warning, error, auth, fatal, bug };
router id #{host.id.first_ipv4.first_ipv4.to_s};
protocol device {
}
protocol direct {
}
protocol kernel {
        learn;
        persist;                # Don't remove routes on bird shutdown
        scan time 20;           # Scan kernel routing table every 20 seconds
        export all;             # Default is export none
}
protocol static {
}

BGP
          Bgps.filters.each do |filter|
            ret = ret + "filter filter_#{filter.name} {\n"
            filter.list.each do |rule|
              nets = rule['network']
              if nets.kind_of?(String)
                #binding.pry
                nets = Construqt::Tags.find(nets, mode.net_clazz)
                #            puts ">>>>>>>>>> #{nets.map{|i| i.class.name}}"
                nets = IPAddress::summarize(nets)
              else
                nets = nets.ips
              end

              nets.each do |ip|
                next unless mode.filter.call(ip)
                ip_str = ip.to_string
                if rule['addr_sub_prefix']
                  ip_str = "#{ip.to_string}{#{ip.prefix},#{ip.ipv4? ? 32 : 128}}"
                elsif rule['prefix_length']
                  ip_str = "#{ip.to_string}{#{rule['prefix_length'].first},#{rule['prefix_length'].last}}"
                end

                ret = ret + "  if net ~ [ #{ip_str} ] then { print \"#{rule['rule']}:\",net; #{rule['rule']}; }\n"
              end
            end

            ret = ret + "}\n\n"
          end

          ret
        end

        def build_bird_conf
          if self.my.address.first_ipv4 && self.other.my.address.first_ipv4
            self.my.host.result.add(self, <<BGP, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::BGP), "etc", "bird", "bird.conf")
protocol bgp #{Util.clean_bgp(self.my.host.name)}_#{Util.clean_bgp(self.other.host.name)} {
        description "#{self.my.host.name} <=> #{self.other.host.name}";
        direct;
        next hop self;
            #{self.as == self.other.as ? '' : '#'}rr client;
        local #{self.my.address.first_ipv4} as #{self.as.num};
        neighbor #{self.other.my.address.first_ipv4}  as #{self.other.as.num};
        password "#{Util.password(self.cfg.password)}";
        import #{self.filter['in'] ? "filter filter_"+self.filter['in'].name : "all"};
        export #{self.filter['out'] ? "filter filter_"+self.filter['out'].name : "all"};
}
BGP
          end
        end

        def build_bird6_conf
          if self.my.address.first_ipv6 && self.other.my.address.first_ipv6
            self.my.host.result.add(self, <<BGP, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::BGP), "etc", "bird", "bird6.conf")
protocol bgp #{Util.clean_bgp(self.my.host.name)}_#{Util.clean_bgp(self.other.host.name)} {
        description "#{self.my.host.name} <=> #{self.other.host.name}";
        direct;
        next hop self;
        #{self.as == self.other.as ? '' : '#'}rr client;
        local #{self.my.address.first_ipv6} as #{self.as.num};
        neighbor #{self.other.my.address.first_ipv6}  as #{self.other.as.num};
        password "#{Util.password(self.cfg.password)}";
        import #{self.filter['in'] ? "filter filter_"+self.filter['in'].name : "all"};
        export #{self.filter['out'] ? "filter filter_"+self.filter['out'].name : "all"};
}
BGP
          end
        end

        def build_config(unused, unused1)
          # binding.pry
          build_bird_conf
          build_bird6_conf
        end
      end
    end
  end
end
