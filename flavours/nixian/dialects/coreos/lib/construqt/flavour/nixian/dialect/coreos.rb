
require 'construqt/flavour/nixian.rb'


require 'construqt/flavour/nixian/dialect/ubuntu'

require 'construqt/flavour/nixian/services'

require_relative 'coreos/services/cloud_init_impl.rb'
require_relative 'coreos/services/remote_deploy_sh.rb'
require_relative 'coreos/services/vagrant_impl.rb'
require_relative 'coreos/services/ssh_authorized_keys_d.rb'
#require_relative 'coreos/services/modules_conf_impl.rb'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module CoreOs
          DIRECTORY = File.dirname(__FILE__)

          class Factory
            def name
              "coreos"
            end

            def produce(parent, cfg)
              Dialect.new(parent, cfg)
            end
          end

          class Dialect
            attr_reader :services_factory, :update_channel, :image_version
            def initialize(factory, cfg)
              @factory = factory
              @cfg = cfg
              @update_channel = cfg['update_channel'] || 'stable'
              @image_version = cfg['image_version'] || 'current'
              @services_factory = factory.services_factory.shadow()
              @services_factory.add(Services::RemoteDeploySh::Factory.new)
              @services_factory.add(Services::CloudInit::Factory.new)
              @services_factory.add(Services::Vagrant::Factory.new)
              @services_factory.add(Services::SshAuthorizedKeysD::Factory.new)
              # binding.pry
            end

            def name
              'coreos'
            end

            def add_host_services(srvs)
              @services_factory.merge(srvs, [
                      Construqt::Packages::Builder.new,
                      Construqt::Flavour::Nixian::Services::DeployerSh::Service.new,
                       Construqt::Flavour::Nixian::Services::Result::Service.new,
                       Construqt::Flavour::Nixian::Services::UpDowner::Service.new
                         .taste(Tastes::Systemd::Factory.new),
                       Construqt::Flavour::Nixian::Services::SysCtlConf::Service.new.fname("/etc/sysctl.d/construqt.conf"),
                       Construqt::Flavour::Nixian::Services::Invocation::Service.new,
                       Construqt::Flavour::Nixian::Services::Docker::Service.new,
                       Construqt::Flavour::Nixian::Services::Vagrant::Service.new,
                       Construqt::Flavour::Nixian::Dialect::CoreOs::Services::SshAuthorizedKeysD::Service.new,
                       Construqt::Flavour::Nixian::Services::Ssh::Service.new,
                       Construqt::Flavour::Nixian::Services::EtcSystemdNetlink::Service.new,
                       Construqt::Flavour::Nixian::Services::EtcSystemdNetdev::Service.new,
                       Construqt::Flavour::Nixian::Services::EtcSystemdNetwork::Service.new,
                       Construqt::Flavour::Nixian::Services::EtcSystemdService::Service.new,
                       Construqt::Flavour::Nixian::Dialect::CoreOs::Services::RemoteDeploySh::Service.new,
                       Construqt::Flavour::Nixian::Services::ModulesConf::Service.new,
                       Construqt::Flavour::Nixian::Dialect::CoreOs::Services::CloudInit::Service.new,
                       Construqt::Flavour::Nixian::Services::RejectRoutes::Service.new
             ])
            end

            def add_interface_services(srvs, cfg)
              @services_factory.merge(srvs, [
                Construqt::Flavour::Nixian::Services::IpTables::Service.new(),
                Construqt::Flavour::Nixian::Services::IpProxyNeigh::Service.new(),
                Construqt::Flavour::Nixian::Services::DnsMasq::Service.new(),
                Construqt::Flavour::Nixian::Services::DhcpClient::Service.new()
              ])
            end

            def ipsec
              Ipsec::StrongSwan
            end

            def bgp
              Bgp
            end

            def clazzes
              {
                "opvn" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Opvn,
                "gre" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Gre,
                "host" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Host,
                "device"=> Construqt::Flavour::Nixian::Dialect::Ubuntu::Device,
                "vrrp" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Vrrp,
                "bridge" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Bridge,
                "bond" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Bond,
                "wlan" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Wlan,
                "tunnel" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Tunnel,
                "vlan" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Vlan,
                "ipsecvpn" => Construqt::Flavour::Nixian::Dialect::Ubuntu::IpsecVpn,
                #"result" => Result,
                #"ipsec" => Ipsec,
                #"bgp" => Bgp,
                "template" => Construqt::Flavour::Nixian::Dialect::Ubuntu::Template
              }
            end

            def clazz(name)
              ret = self.clazzes[name]
              throw "class not found #{name}" unless ret
              ret
            end

            def create_host(name, cfg)
              cfg['name'] = name
              cfg['result'] = nil
              host = Construqt::Flavour::Nixian::Dialect::Ubuntu::Host.new(cfg)
              host
            end

            # def vagrant_factory(host, ohost)
            #   VagrantFile.new(host, ohost)
            # end

            def create_interface(name, cfg)
              cfg['name'] = name
              clazz(cfg['clazz']).new(cfg)
            end

            def create_bgp(cfg)
              Bgp.new(cfg)
            end

            def create_ipsec(cfg)
              Ipsec::StrongSwan.new(cfg)
            end
          end
        end
      end
    end
  end
end
