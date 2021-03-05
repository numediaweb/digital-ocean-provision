# -*- mode: ruby -*-
# vi: set ft=ruby
# Load configuration settings
dir = File.dirname(File.expand_path(__FILE__))
require 'yaml'
require "#{dir}/ruby/deep_merge.rb"
require "#{dir}/ruby/os.rb"
if File.file?("config.yml")
	parameters = YAML.load_file 'config.yml'
else
	parameters = {}
end

# Merge custom config
if File.file?("config-custom.yml")
	custom = YAML.load_file("config-custom.yml")
	parameters.deep_merge!(custom)
end

# Variables
VAGRANTFILE_API_VERSION = "2"
VAGRANTFILE_VM_BOX = "digital_ocean"
VAGRANTFILE_VM_BOX_URL = "https://github.com/devopsgroup-io/vagrant-digitalocean/raw/master/box/digital_ocean.box"
VAGRANTFILE_PROVIDER_IMAGE = "ubuntu-18-04-x64"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config| # start config
    parameters['droplets'].each do |droplet| # start loop

        config.vm.define droplet['name'] do |config| # start box

            config.vm.provider :digital_ocean do |provider, override| # start provider
                override.ssh.username = "vagrant"
                override.ssh.private_key_path = parameters['vagrant']['ssh']['private_key_path']
                override.vm.box = VAGRANTFILE_VM_BOX
                override.vm.box_url = VAGRANTFILE_VM_BOX_URL
                override.nfs.functional = false
                override.vm.allowed_synced_folder_types = :rsync
                provider.token = parameters['digitalocean']['token']
                provider.image = VAGRANTFILE_PROVIDER_IMAGE
                provider.region = droplet['region']
                provider.size = droplet['size']
            end

            config.vm.provision "ansible_local" do |ansible| # start ansible
                ansible.playbook = "ansible/playbook.yml"
                ansible.compatibility_mode = "2.0"
                ansible.extra_vars = {
                    "droplet" => droplet,
                    "config" => parameters,
                    "roles_enabled" => droplet['roles']
                }
            end # end ansible
        end # end box

    end # end loop

end # end config
