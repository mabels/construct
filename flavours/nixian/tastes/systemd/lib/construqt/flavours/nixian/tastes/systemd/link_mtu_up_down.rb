module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class LinkMtuUpDown
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::LinkMtuUpDown, LinkMtuUpDown)
        end
      end
    end
  end
end
