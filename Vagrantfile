# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "oraclelinux/9"
  config.vm.box_url = "https://oracle.github.io/vagrant-projects/boxes/oraclelinux/9.json"

  # --------------------------------------------------------------------------
  # VM 1: DB-сервер (PostgreSQL)
  # --------------------------------------------------------------------------
  config.vm.define "dbserver" do |db|
    db.vm.hostname = "pyforum-oracle9-pgsqldbserver"
    db.vm.network "private_network", ip: "192.168.56.20"
    db.vm.provider "virtualbox" do |vb|
      vb.name   = "pyforum-oracle9-pgsqldbserver"
      vb.memory = "1024"
      vb.cpus   = 1
    end
  end

  # --------------------------------------------------------------------------
  # VM 2: App-сервер (Django + Gunicorn)
  # --------------------------------------------------------------------------
  config.vm.define "appserver" do |app|
    app.vm.hostname = "pyforum-oracle9-appserver"
    app.vm.network "private_network", ip: "192.168.56.10"
    app.vm.network "forwarded_port", guest: 8000, host: 8000
    app.vm.synced_folder ".", "/home/vagrant/pyforum"
    app.vm.provider "virtualbox" do |vb|
      vb.name   = "pyforum-oracle9-appserver"
      vb.memory = "1024"
      vb.cpus   = 1
    end
  end

  # --------------------------------------------------------------------------
  # VM 3: Vault node (HashiCorp Vault, dev mode)
  # --------------------------------------------------------------------------
  config.vm.define "vaultnode" do |vault|
    vault.vm.hostname = "pyforum-oracle9-vaultnode"
    vault.vm.network "private_network", ip: "192.168.56.40"
    vault.vm.provider "virtualbox" do |vb|
      vb.name   = "pyforum-oracle9-vaultnode"
      vb.memory = "512"
      vb.cpus   = 1
    end
    vault.vm.provision "shell", path: "DevOps_Scripts/pyforum-provision-vault.sh"
  end

  # --------------------------------------------------------------------------
  # VM 4: Ansible Control Node
  # После vagrant up:
  #   vagrant ssh controlnode
  #   cd /home/vagrant/pyforum/ansible
  #   ansible-playbook -i inventory/hosts.ini playbooks/dbserver.yml
  #   ansible-playbook -i inventory/hosts.ini playbooks/appserver.yml
  # --------------------------------------------------------------------------
  config.vm.define "controlnode" do |ctrl|
    ctrl.vm.hostname = "pyforum-oracle9-controlnode"
    ctrl.vm.network "private_network", ip: "192.168.56.30"
    ctrl.vm.synced_folder ".", "/home/vagrant/pyforum"
    ctrl.vm.provider "virtualbox" do |vb|
      vb.name   = "pyforum-oracle9-controlnode"
      vb.memory = "512"
      vb.cpus   = 1
    end
    ctrl.vm.provision "shell", path: "DevOps_Scripts/pyforum-provision-controlnode.sh"
  end

end
