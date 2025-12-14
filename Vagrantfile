Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

   config.vm.define "BD1Alexandro" do |bd1|
    bd1.vm.hostname = "BD1Alexandro"
    bd1.vm.network "private_network", ip: "192.168.4.2"
    bd1.vm.provision "shell", path: "Aprovisionamiento/BD1.sh"
  end

  config.vm.define "BD2Alexandro" do |bd2|
    bd2.vm.hostname = "BD2Alexandro"
    bd2.vm.network "private_network", ip: "192.168.4.3"
    bd2.vm.provision "shell", path: "Aprovisionamiento/BD2.sh"
  end

  config.vm.define "ProxyBDAlexandro" do |proxy|
    proxy.vm.hostname = "ProxyBDAlexandro"
    proxy.vm.network "private_network", ip: "192.168.4.1"
    proxy.vm.network "private_network", ip: "192.168.3.2"
    proxy.vm.provision "shell", path: "Aprovisionamiento/ProxyBD.sh"
  end

  config.vm.define "ServerNFSAlexandro" do |nfs|
    nfs.vm.hostname = "ServerNFSAlexandro"
    nfs.vm.network "private_network", ip: "192.168.3.1"
    nfs.vm.network "private_network", ip: "192.168.2.4"
    nfs.vm.provision "shell", path: "Aprovisionamiento/NFS.sh"
  end

  config.vm.define "ServerWEB1Alexandro" do |web1|
    web1.vm.hostname = "ServerWEB1Alexandro"
    web1.vm.network "private_network", ip: "192.168.2.2"
    web1.vm.provision "shell", path: "Aprovisionamiento/Web.sh"
  end

  config.vm.define "ServerWEB2Alexandro" do |web2|
    web2.vm.hostname = "ServerWEB2Alexandro"
    web2.vm.network "private_network", ip: "192.168.2.3"
    web2.vm.provision "shell", path: "Aprovisionamiento/Web.sh"
  end

  config.vm.define "BalanceadorAlexandro" do |bl|
    bl.vm.hostname = "BalanceadorAlexandro"
    bl.vm.network "private_network", ip: "192.168.2.1"
    bl.vm.network "private_network", ip: "192.168.1.1"
    bl.vm.network "forwarded_port", guest: 80, host: 8081
    bl.vm.provision "shell", path: "Aprovisionamiento/BL.sh"
  end
