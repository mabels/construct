require_relative './ipsec/ipsec_cert_store'
require_relative './ipsec/ipsec_secret'
require_relative './result'
module Construqt
  module Flavour
    module Nixian
      module Services
        module Gre
          class Connection
            attr_accessor :delegate, :other, :cfg, :interface
            attr_reader :host, :my, :other, :firewalls, :remote
            attr_reader :any, :transport_left, :transport_right
            attr_reader :leftsubnet, :sourceip, :auto
            def initialize(cfg)
              @host = cfg["host"]
              @my = cfg["my"]
              @other = cfg["other"]
              @firewalls = cfg["firewalls"]
              @remote = cfg["remote"]
              @interface = cfg["interface"]
              @any = cfg["any"]
              @transport_left = cfg["transport_left"]
              @transport_right = cfg["transport_right"]
              @leftsubnet = cfg["leftsubnet"]
              @any = cfg["any"]
              @sourceip = cfg["sourceip"]
              @auto = cfg["auto"]
            end
            def build_config(host, service, node)
            end
          end
          class Service
            def initialize
            end
          end

          class OncePerHost
            def initialize #(result_types, host)
              # binding.pry
              # @result_types = result_types
              #@host = host
              @connections = Set.new()
            end

            def attach_host(host)
              @host = host
            end

            def activate(ctx)
              @context = ctx
              @result = ctx.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
            end

            def add(*a)
              @result.add(*a)
            end

            def start
              #@ipsec_secret.header
            end

            def render_conn(conn, service)
              out = ["conn #{service.host.name}-#{service.other.host.name}"]
              conn.to_h.each do |k,v|
                out << Util.indent("#{k}=#{v}", 3)
              end

              out.join("\n")
            end

            def build_config_host
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              host = @host
              # binding.pry
              Set.new(@host.tunnels.map{|i| i.endpoints }.flatten).select do
                |i| i.host.ident == @host.ident
              end.each do |service|
                next if true
                if service.tunnel.transport_family == Construqt::Addresses::IPV6
                  local_if = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(service.remote.address.first_ipv6) }
                  transport_left=service.remote.first_ipv6.to_s
                  transport_right=service.other.remote.service_ip.first_ipv6.to_s
                  leftsubnet = service.my.ips.select{|i| i.ipv6? }.map{|i| i.to_s }.first # join(',')
                  rightsubnet = service.other.my.ips.select{|i| i.ipv6? }.map{|i| i.to_s }.first #.join(',')
                  gt = "gt6"
                else
                  # local_if = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(service.remote.address.first_ipv4) }
                  # transport_left=service.remote.address.first_ipv4.to_s
                  # transport_right=service.other.remote.service_ip.first_ipv4.to_s
                  # leftsubnet = service.my.ips.select{|i| i.ipv4? }.map{|i| i.to_s }.first # join(',')
                  # rightsubnet = service.other.my.ips.select{|i| i.ipv4? }.map{|i| i.to_s }.first #.join(',')
                  gt = "gt4"
                end

                if leftsubnet.nil? or leftsubnet.empty? or
                   rightsubnet.nil? or rightsubnet.empty?
                  next
                  #throw "we need a transport_left and transport_right for #{service.host.name}-#{service.other.host.name}"
                end

                # if local_if.clazz == "vrrp"
                #   writer = host.result.etc_network_vrrp(local_if.name)
                #   writer.add_master("/usr/sbin/ipsec up #{service.host.name}-#{service.other.host.name} &", 1000)
                #   writer.add_backup("/usr/sbin/ipsec down #{service.host.name}-#{service.other.host.name} &", -1000)
                #   local_if.services << Construqt::Services::IpsecStartStop.new
                # end

                # ioph = @context.find_instances_from_type(OncePerHost)
                # ioph.ipsec_secret.add_psk(transport_right, service.cfg.password, service.cfg.name)
                # ioph.ipsec_secret.add_psk(service.other.host.name, service.cfg.password)
                #
                # conn = OpenStruct.new
                # conn.leftid=service.host.name
                # conn.rightid=service.other.host.name
                # conn.left=(service.any && "%any") || transport_left
                # conn.right=(service.other.any && "%any") || transport_right
                # conn.leftsubnet=leftsubnet
                # if (service.other.sourceip)
                #   conn.leftsourceip="%config"
                # end
                #
                # conn.rightsubnet=rightsubnet
                # if (service.sourceip)
                #   conn.rightsourceip=rightsubnet
                # end
                #
                # conn.esp=service.cfg.cipher || "aes256-sha1-modp1536"
                # conn.ike=service.cfg.cipher || "aes256-sha1-modp1536"
                # conn.compress="no"
                # conn.ikelifetime="60m"
                # conn.keylife="20m"
                # conn.keyingtries="0"
                # conn.keyexchange=service.cfg.keyexchange || "ike"
                # conn.type="tunnel"
                # conn.authby="secret"
                # conn.dpdaction="restart"
                # conn.dpddelay="120s"
                # conn.dpdtimeout="180s"
                # conn.rekeymargin="3m"
                # conn.closeaction="restart"
                # binding.pry
                conn.auto=service.auto || "start"
                result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
                # result.add(:ipsec, render_conn(conn, service),
                #            Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC),
                #            "etc", "ipsec.conf")
              end
            end

            def commit
            end
          end

          class Action
            attr_reader :host, :service
            def initialize(host, service)
              @host = host
              @service = service #.ipsec
            end

            def activate(ctx)
              @context = ctx
            end

            def build_interface(host, ifname, iface, writer)
              #binding.pry
            end



            def build_config_host#(host, service)
              end

            def commit
              #binding.pry
            end
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              # binding.pry
              @machine ||= service_factory.machine
                .service_type(Service)
                .result_type(OncePerHost)
                .depend(Result::Service)
            end

            def produce(host, srv_inst, ret)
              Action.new(host, srv_inst)
            end
          end
        end
      end
    end
  end
end
