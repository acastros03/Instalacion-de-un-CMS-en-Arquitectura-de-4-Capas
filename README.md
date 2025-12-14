# Instalación de un CMS en Arquitectura de 4 Capas

## 📑 Índice

* [Introducción](#introduccion)
* [Arquitectura del sistema](#arquitectura-del-sistema)
* [Estructura de red](#estructura-de-red)
* [Estructura del proyecto](#estructura-del-proyecto)
* [Vagrantfile](#vagrantfile)
* [Aprovisionamiento con Vagrant](#aprovisionamiento-con-vagrant)
* [Scripts de aprovisionamiento](#scripts-de-aprovisionamiento)
* [Funcionamiento de la capa web](#funcionamiento-de-la-capa-web)
* [Conclusión](#conclusion)
* [Comprobación](#comprobacion)

---

## 🖥️ Introducción

Este proyecto consiste en el despliegue de una **arquitectura de 4 capas en alta disponibilidad** utilizando **Vagrant** con **Debian Bookworm**, orientada a la instalación de un **CMS WordPress**.

La arquitectura separa claramente las responsabilidades de cada capa:

* Balanceo de carga HTTP
* Servidores web sin ejecución de PHP
* Almacenamiento compartido y ejecución de PHP mediante NFS
* Base de datos MariaDB en alta disponibilidad con Galera y HAProxy

Todo el sistema se despliega automáticamente mediante **scripts Bash**.

---

## 🌐 Arquitectura del sistema

### Descripción general

* **Balanceador**: NGINX como proxy inverso y balanceador HTTP.
* **Servidores Web**: NGINX sirviendo contenido desde NFS, sin PHP local.
* **Servidor NFS**: Almacenamiento compartido, PHP-FPM y código del CMS.
* **Base de Datos**: MariaDB en clúster Galera con HAProxy como proxy TCP.

---

## 🖧 Estructura de red

### Tabla de direccionamiento IP

| Máquina              | Rol               | IP                        | Red      |
| -------------------- | ----------------- | ------------------------- | -------- |
| BalanceadorAlexandro | Balanceador NGINX | 192.168.2.1 / 192.168.1.1 | Frontend |
| ServerWEB1Alexandro  | Servidor Web      | 192.168.2.2               | Web      |
| ServerWEB2Alexandro  | Servidor Web      | 192.168.2.3               | Web      |
| ServerNFSAlexandro   | NFS + PHP-FPM     | 192.168.3.1 / 192.168.2.4 | Backend  |
| ProxyBDAlexandro     | HAProxy MariaDB   | 192.168.4.1 / 192.168.3.2 | BD       |
| BD1Alexandro         | MariaDB           | 192.168.4.2               | BD       |
| BD2Alexandro         | MariaDB           | 192.168.4.3               | BD       |

---

## 📂 Estructura del proyecto

```
.
├── Vagrantfile
└── Aprovisionamiento
    ├── BL.sh
    ├── Web.sh
    ├── NFS.sh
    ├── ProxyBD.sh
    ├── BD1.sh
    └── BD2.sh
```

---

## 📄 Vagrantfile

En este apartado se incluye el fichero `Vagrantfile`, encargado de definir todas las máquinas virtuales, sus interfaces de red y los scripts de aprovisionamiento asociados a cada una de ellas.

```ruby
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
```

---

## ⚙️ Aprovisionamiento con Vagrant

El despliegue de las máquinas virtuales se realiza mediante **Vagrant**, utilizando un único `Vagrantfile` que define todas las máquinas y ejecuta los scripts de aprovisionamiento correspondientes.

Los **dos servidores web utilizan el mismo script** (`Web.sh`).

---

## 📝 Scripts de aprovisionamiento

### Balanceador (BL.sh)

*pongo aquí el script*

### Servidor Web (Web.sh)

*pongo aquí el script*

### Servidor NFS (NFS.sh)

*pongo aquí el script*

### Proxy MariaDB (ProxyBD.sh)

*pongo aquí el script*

### BD1 (BD1.sh)

*pongo aquí el script*

### BD2 (BD2.sh)

*pongo aquí el script*

---

## 🌊 Funcionamiento de la capa web

Los servidores web:

* No ejecutan PHP localmente
* Sirven contenido desde NFS
* Reenvían las peticiones PHP al servidor NFS mediante FastCGI

Esto permite escalabilidad, centralización del código y menor carga en los servidores web.

---

## ✅ Conclusión

La arquitectura desplegada cumple los objetivos del proyecto:

* Alta disponibilidad
* Separación clara de capas
* Balanceo de carga funcional
* Centralización del código y PHP
* Despliegue automático y reproducible

El sistema es accesible desde la máquina anfitriona.

---

## 🎬 Comprobación

Video de comprobacion: [añado yo el link del video]
