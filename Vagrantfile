# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  config.vm.box = "debian/jessie64"
  config.vm.box_url = "https://atlas.hashicorp.com/debian/boxes/jessie64"

  config.vm.network "forwarded_port", guest: 80, host: 80

  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  config.vm.synced_folder ".", "/var/www", create: true, type: "virtualbox"

  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 2
  end

  config.berkshelf.enabled = true
  config.berkshelf.berksfile_path = "./cookbooks/custom/Berksfile"

  config.vm.provision :chef_solo do |chef|
    chef.add_recipe "apt"
    chef.add_recipe "build-essential"
    chef.add_recipe "openssl"
    chef.add_recipe "custom"
    chef.add_recipe "logrotate"
    chef.json = {
      :custom => {
        :dump_url => 'URL',
        :conf_url => 'URL',
        :login => 'LOGIN',
        :password => 'PASSWORD'
      },
      :apache => {
        :default_site_enabled => true,
        :docroot_dir => "/var/www"
      },
      :apt => { :compiletime => true },
      :php => {
        :directives => {
          :short_open_tag => "On"
        }
      }
    }
  end
end
