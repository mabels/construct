module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu


          class Bridge < OpenStruct
            include Construqt::Cables::Plugin::Multiple
            def initialize(cfg)
              super(cfg)
            end

            def build_config(host, iface)
              unless iface.interfaces.empty?
                port_list = iface.interfaces.map { |i| i.name }.join(" ")
                host.result.etc_network_interfaces.get(iface).lines.add("bridge_ports #{port_list}")
              else
                host.result.etc_network_interfaces.get(iface).lines.add("bridge_ports none")
              end
              iface.on_iface_up_down do |writer, ifname|
                writer.lines.up("brctl addbr #{ifname}")
                writer.lines.down("brctl delbr #{ifname}")
              end
              Device.build_config(host, iface)
            end
          end
        end
      end
    end
  end
end
