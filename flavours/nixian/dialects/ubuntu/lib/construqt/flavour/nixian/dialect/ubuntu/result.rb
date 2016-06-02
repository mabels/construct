
require 'shellwords'
require 'net/http'
require 'json'


require_relative 'result/etc_network_vrrp'
require_relative 'result/etc_network_interfaces'
require_relative 'result/etc_network_iptables'
require_relative 'result/etc_conntrackd_conntrackd'
require_relative 'ipsec/ipsec_secret'
require_relative 'ipsec/ipsec_cert_store'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Result
            attr_reader :etc_network_interfaces, :etc_network_iptables, :etc_conntrackd_conntrackd
            attr_reader :ipsec_secret, :ipsec_cert_store, :host, :package_builder, :results
            def initialize(host)
              @host = host
              @etc_network_interfaces = EtcNetworkInterfaces.new(self)
              @etc_network_iptables = EtcNetworkIptables.new
              @etc_conntrackd_conntrackd = EtcConntrackdConntrackd.new(self)
              @etc_network_vrrp = EtcNetworkVrrp.new
              @ipsec_secret = Ipsec::IpsecSecret.new(self)
              @ipsec_cert_store = Ipsec::IpsecCertStore.new(self)
              @package_builder = Result.create_package_builder()
              @results = {}
            end

            def self.create_package_builder
              cps = Packages::Builder.new()
              cp = Construqt::Resources::Component
              cps.register(cp::UNREF).add("language-pack-en").add("language-pack-de")
                            .add("git").add("aptitude").add("traceroute")
                            .add("tcpdump").add("strace").add("lsof")
                            .add("ifstat").add("mtr-tiny").add("openssl")
              cps.register("Construqt::Flavour::Delegate::DeviceDelegate")
              cps.register("Construqt::Flavour::Nixian::Dialect::Ubuntu::Wlan")
              cps.register("Construqt::Flavour::Nixian::Dialect::Ubuntu::Bond").add("ifenslave")
              cps.register("Construqt::Flavour::Delegate::VlanDelegate").add("vlan")
              cps.register("Construqt::Flavour::Nixian::Dialect::Ubuntu::Gre")
              cps.register("Construqt::Flavour::Delegate::GreDelegate")
              cps.register("Construqt::Flavour::Delegate::BridgeDelegate").add("bridge-utils")
              cps.register(cp::NTP).add("ntpd")
              cps.register(cp::USB_MODESWITCH).add("usb-modeswitch").add("usb-modeswitch-data")
              cps.register(cp::VRRP).add("keepalived")
              cps.register(cp::FW4).add("iptables").add("ulogd2")
              cps.register(cp::FW6).add("iptables").add("ulogd2")
              cps.register(cp::IPSEC).add("strongswan")
                .add("strongswan-plugin-eap-mschapv2")
                .add("strongswan-plugin-xauth-eap")
              cps.register(cp::SSH).add("openssh-server")
              cps.register(cp::BGP).add("bird")
              cps.register(cp::OPENVPN).add("openvpn")
              cps.register(cp::DNS).add("bind9")
              cps.register(cp::RADVD).add("radvd")
              cps.register(cp::DNSMASQ).add("dnsmasq").cmd('update-rc.d dnsmasq disable')
              cps.register(cp::CONNTRACKD).add("conntrackd").add("conntrack")
              cps.register(cp::LXC).add("lxc").add("ruby").add("rubygems-integration")
                  .cmd('[ "$(gem list -i linux-lxc)" = "true" ] || gem install linux-lxc --no-ri --no-rdoc')
              cps.register(cp::DHCPRELAY).add("wide-dhcpv6-relay").add("dhcp-helper")
              cps.register(cp::WIRELESS).both("crda").both("iw").mother("linux-firmware")
                  .add("wireless-regdb").add("wpasupplicant")
              cps
            end

            def etc_network_vrrp(ifname)
              @etc_network_vrrp.get(ifname)
            end


            def add_component(component)
              @results[component] ||= ArrayWithRightAndClazz.new(Construqt::Resources::Rights.root_0644(component), component.to_sym)
            end

            def empty?(name)
              not @results[name]
            end

            class ArrayWithRightAndClazz < Array
              attr_accessor :right, :clazz
              def initialize(right, clazz)
                self.right = right
                self.clazz = clazz
              end

              def skip_git?
                !!@skip_git
              end

              def skip_git
                @skip_git = true
              end
            end

            def add(clazz, block, right, *path)
              path = File.join(*path)
              throw "not a right #{path}" unless right.respond_to?('right') && right.respond_to?('owner')
              unless @results[path]
                @results[path] = ArrayWithRightAndClazz.new(right, clazz)
                #binding.pry
                #@results[path] << [clazz.xprefix(@host)].compact
              end
              throw "clazz missmatch for path:#{path} [#{@results[path].clazz.class.name}] [#{clazz.class.name}]" unless clazz == @results[path].clazz
              @results[path] << block+"\n"
              @results[path]
            end

            def replace(clazz, block, right, *path)
              path = File.join(*path)
              replaced = !!@results[path]
              @results.delete(path) if @results[path]
              add(clazz, block, right, *path)
              replaced
            end

            def directory_mode(mode)
              mode = mode.to_i(8)
              0!=(mode & 06) && (mode = (mode | 01))
              0!=(mode & 060) && (mode = (mode | 010))
              0!=(mode & 0600) && (mode = (mode | 0100))
              "0#{mode.to_s(8)}"
            end

            def sh_function_git_add()
              Construqt::Util.render(binding, "result_git_add.sh.erb")
            end

            def setup_ntp(host)
              ["cp /usr/share/zoneinfo/#{host.time_zone || host.region.network.ntp.get_timezone} /etc/localtime"]
            end

            def sh_is_opt_set
              Construqt::Util.render(binding, "result_is_opt_set.sh.erb")
            end

            def sh_install_packages
              Construqt::Util.render(binding, "result_install_packages.sh.erb")
            end

            def write_file(host, fname, block)
              if host.files
                return [] if host.files.find do |file|
                  file.path == fname && file.kind_of?(Construqt::Resources::SkipFile)
                end
              end
              text = block.flatten.select{|i| !(i.nil? || i.strip.empty?) }.join("\n")
              return [] if text.strip.empty?
              Util.write_str(@host.region, text, @host.name, fname)
              gzip_fname = Util.write_gzip(@host.region, text, @host.name, fname)
              [
                File.dirname("/#{fname}").split('/')[1..-1].inject(['']) do |res, part|
                  res << File.join(res.last, part); res
                end.select{|i| !i.empty? }.map do |i|
                  "[ ! -d #{i} ] && mkdir #{i} && chown #{block.right.owner} #{i} && chmod #{directory_mode(block.right.right)} #{i}"
                end,
                "import_fname #{fname}",
                "base64 --decode <<BASE64 | gunzip > $IMPORT_FNAME", Base64.encode64(IO.read(gzip_fname)).chomp, "BASE64",
                "git_add #{["/"+fname, block.right.owner, block.right.right, block.skip_git?].map{|i| '"'+Shellwords.escape(i)+'"'}.join(' ')}"
              ]

            end

            def offline_package
              queue = Queue.new
              uri = URI('https://woko.construqt.net:7878/')
              req = Net::HTTP::Post.new(uri, initheader = {
                  'Content-Type' =>'application/json'
                })
              package_params = {
                "dist": "ubuntu",
                "arch": "amd64",
                "version": "xenial",
                "packages": Lxc.package_list(@host)
              }
              req.body = package_params.to_json
              res = Net::HTTP.start(uri.hostname, uri.port) do |http|
                http.request(req)
              end
              packages = JSON.parse(res.body)
              packages.each do |pkg|
                queue << pkg
              end
              cache_path = File.join(Construqt::Util.dst_path(@host.region),
                ".package-cache",
                "#{package_params["dist"]}-#{package_params["version"]}-#{package_params["arch"]}")
              threads = [8, queue.size].min.times.map do
                Thread.new do
                      while !queue.empty? && pkg = queue.pop
                        fname = File.join(cache_path, pkg['name'])
                        if File.exist?(fname)
                          throw "unknown sum_type #{fname} #{pkg['sum_type']}" unless ['MD5Sum'].includes?(pkg['sum_type'])
                          if Digest::MD5.file(fname).hexdigest.downcase == pkg['sum'].downcase
                            next
                          end
                        end
                        Construqt.logger.debug "Download from #{pkg['url']}"
                        uri = URI(pkg['url'])
                        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
                          res =  http.request(Net::HTTP::Get.new(uri))
                          if Digest::MD5.hexdigest(res.body).downcase != pkg['sum'].downcase
                            throw "downloaded file #{pkg['url']} checksum missmatch #{pkg['sum']}"
                          end
                          FileUtils.mkdir_p(File.dirname(fname))
                          File.open(fname, 'w') { |file| file.write(res.body) }
                        end
                      end
                    end
                  end
                end
                threads.each(&:join)
              end
              var_cache_path = "/var/cache/apt/archives"
              Util.open_file(@host.region, @host.name, "packager.sh") do |f|
                f.println("#!/bin/bash")
                f.println("ARGS=$@")
                f.println("mkdir -p #{var_cache_path}")
                packages.each do |pkg|
                  fname = File.join(cache_path, pkg['name'])
                  f.println("echo packager extract #{pkg['name']}")
                  f.println "base64 --decode <<BASE64 > #{File.join(var_cache_path, pkg['name'])}"
                  f.println  Base64.encode64(IO.read(fname))
                  f.println "BASE64"
                end
              end
              [ "if [ -f "packager.sh" ]",
                "then",
                "  sh packager.sh"
                "fi"].join("\n")
            end

            def commit
              add(EtcNetworkIptables, etc_network_iptables.commitv4, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW4), "etc", "network", "iptables.cfg")
              add(EtcNetworkIptables, etc_network_iptables.commitv6, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW6), "etc", "network", "ip6tables.cfg")
              add(EtcNetworkInterfaces, etc_network_interfaces.commit, Construqt::Resources::Rights.root_0644, "etc", "network", "interfaces")
              @etc_network_vrrp.commit(self)
              ipsec_secret.commit
              ipsec_cert_store.commit

              Lxc.write_deployers(@host)
              out = ["#!/bin/bash", "ARGS=$@"]

              out << sh_is_opt_set
              out << sh_function_git_add
              out << sh_install_packages
              out << offline_package

              out << Construqt::Util.render(binding, "result_package_list.sh.erb")


              out << "for i in $(seq 8)"
              out << "do"
              out << "  systemctl mask container-getty@\$i.service > /dev/null"
              out << "done"

              out << "if [ $(is_opt_set skip_mother) != found ]"
              out << "then"
              out << Construqt::Util.render(binding, "result_host_check.sh.erb")

              out << "[ $(is_opt_set skip_packages) != found ] && install_packages #{Lxc.package_list(@host).join(" ")}"

              out << Construqt::Util.render(binding, "result_git_init.sh.erb")

              out += setup_ntp(host)
              out += Lxc.commands(@host)

              @results.each do |fname, block|
                if !block.clazz.respond_to?(:belongs_to_mother?) ||
                   block.clazz.belongs_to_mother?
                  out += write_file(host, fname, block)
                end
              end
              out << "fi"
              @results.each do |fname, block|
                if block.clazz.respond_to?(:belongs_to_mother?) && !block.clazz.belongs_to_mother?
                  out += write_file(host, fname, block)
                end
              end
              out += Lxc.deploy(@host)
              out += [Construqt::Util.render(binding, "result_git_commit.sh.erb")]
              Util.write_str(@host.region, out.join("\n"), @host.name, "deployer.sh")
            end
          end
        end
      end
    end
  end
end
