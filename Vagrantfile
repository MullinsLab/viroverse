# -*- mode: ruby -*-
# vi: set ft=ruby ts=2 sw=2 :
require "resolv"

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |vagrant|
  # All Vagrant configuration is done here. For a complete reference, please
  # see the online documentation at vagrantup.com.
  vagrant.vm.define ENV["USER"] + "-dev" do |config|
    config.vm.box = "bento/centos-7.7"

    config.ssh.forward_agent = true

    config.vm.synced_folder "devel/vagrant", "/vagrant"
    config.vm.synced_folder ".", "/home/vagrant/viroverse"

    # A provision hook for provider-specific needs before the main provisioning
    # script.  Normally provider-added provisioning scripts run after those
    # defined in outer scopes, thus we create a hook point which does nothing
    # by itself but can be overridden by a provider.
    config.vm.provision "provider", type: "shell",
      inline: "true",
      keep_color: true

    config.vm.provision "shell",
      inline: "bash /vagrant/provision " + ENV["USER"],
      privileged: false,
      keep_color: true

    # Spin up the VM using VirtualBox on a workstation
    config.vm.provider "virtualbox" do |vb, override|
      vb.name = "localverse"
      vb.memory = 2048
      vb.cpus = 2

      override.vm.hostname = "localverse"
      override.vm.network "private_network", ip: "192.168.0.2"
    end
  end
end
