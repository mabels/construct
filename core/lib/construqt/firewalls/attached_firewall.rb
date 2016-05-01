module Construqt
  module Firewalls
    class AttachedFirewall
      def initialize(iface, firewall)
        @iface = iface
        @firewall = firewall
      end

      def get_raw
        @firewall.get_raw(@iface)
      end

      def get_nat
        @firewall.get_nat(@iface)
      end

      def get_forward
        @firewall.get_forward(@iface)
      end

      def get_host
        @firewall.get_host(@iface)
      end

      def ipv4?
        @firewall.ipv4?
      end

      def ipv6?
        @firewall.ipv6?
      end
    end
  end
end
