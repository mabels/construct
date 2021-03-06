require_relative './result'
module Construqt
  module Flavour
    module Nixian
      module Services
        module EtcNetworkNetworkUd
          class Service
            def initialize()
            end
          end

          class OncePerHost
            attr_reader :ups, :downs
            def initialize
              @ups = []
              @downs = []
            end

            def activate(context)
              @context = context
            end

            def up(up)
              @ups.push(up)
            end

            def down(down)
              @downs.push(down)
            end

            def commit
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              if ups.length > 0
                blocks = ups
                result.add(EtcNetworkNetworkUd, Construqt::Util.render(binding, "interfaces_sh_envelop.erb"),
                           Construqt::Resources::Rights.root_0755,
                           'etc', 'network', "network-up.sh")
                blocks = downs.reverse
                result.add(EtcNetworkNetworkUd, Construqt::Util.render(binding, "interfaces_sh_envelop.erb"),
                           Construqt::Resources::Rights.root_0755,
                           'etc', 'network', "network-down.sh")
              end
            end
          end

          class Action
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              @machine ||= service_factory.machine
                .service_type(Service)
                .result_type(OncePerHost)
                .depend(Result::Service)
                .depend(UpDowner::Service)
            end

            def produce(host, srv_inst, ret)
              Action.new #(host, srv_inst)
            end
          end
        end
      end
    end
  end
end
