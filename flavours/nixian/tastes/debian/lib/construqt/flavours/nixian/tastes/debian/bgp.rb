module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Bgp
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Bgp, Bgp)
        end
      end
    end
  end
end
