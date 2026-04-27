# -*- mode: ruby -*-
# # vi: set ft=ruby :

# NOTE: This monkey-patching is done to force cloud-init over NetworkManager.
# Vagrant attempts to detect cloud-init, but Flatcar doesn't have an executable
# under that name, only coreos-cloudinit.

require Vagrant.source_root.join("plugins/guests/coreos/cap/configure_networks.rb")

module VagrantPlugins
  module GuestCoreOS
    module Cap
      class ConfigureNetworks
        def self.configure_networks(machine, networks)
          configure_networks_cloud_init(machine, networks)
        end
      end
    end
  end
end
