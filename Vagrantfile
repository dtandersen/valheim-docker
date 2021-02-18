# -*- mode: ruby -*-
# vi: set ft=ruby :
# requires set VAGRANT_EXPERIMENTAL="disks"
Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.hostname = "valheim"
  config.vbguest.auto_update = false
  config.ssh.forward_agent = true

  #config.vm.network "private_network", ip: "192.168.50.4", virtualbox__intnet: true
  config.vm.network "forwarded_port", guest: 2456, host: 2456, protocol: "udp"
  config.vm.network "forwarded_port", guest: 2457, host: 2457, protocol: "udp"
  config.vm.network "forwarded_port", guest: 2458, host: 2458, protocol: "udp"
  #config.vm.disk :disk, size: "50GB", primary: true

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.name = "Valheim"
    vb.memory = 4096
    vb.cpus = 4
  end

  config.vm.provision "shell", inline: <<-SHELL
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io
    curl -Ls "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
    chmod +x /usr/bin/docker-compose
    usermod -aG docker vagrant
    cd /vagrant
    docker-compose up -e PASSWORD="hhh" -d
  SHELL
end
