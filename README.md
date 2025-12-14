# Instalación de un CMS en Arquitectura de 4 Capas

## 📑 Índice

* [Introducción](#-introducción)
* [Arquitectura del sistema](#-arquitectura-del-sistema)
* [Estructura de red](#-estructura-de-red)
* [Estructura del proyecto](#-estructura-del-proyecto)
* [Aprovisionamiento con Vagrant](#-aprovisionamiento-con-vagrant)
* [Scripts de aprovisionamiento](#-scripts-de-aprovisionamiento)
* [Funcionamiento de la capa web](#-funcionamiento-de-la-capa-web)
* [Conclusión](#-conclusión)
* [Comprobación](#-comprobación)

## 🖥️ Introducción

Este proyecto consiste en el despliegue de una **arquitectura de 4 capas en alta disponibilidad** utilizando **Vagrant** con **Debian Bookworm**.

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
* **Servidor NFS**: Almacenamiento compartido, PHP-FPM.
* **Base de Datos**: MariaDB en clúster Galera con HAProxy.

---

## 🖧 Estructura de red

### Tabla de direccionamiento IP

| Máquina              | Rol               | IP                        | Red            |
| -------------------- | ----------------- | ------------------------- | -------------- |
| BalanceadorAlexandro | Balanceador NGINX | 192.168.2.1 / 192.168.1.1 | Frontend       |
| ServerWEB1Alexandro  | Servidor Web      | 192.168.2.2               | Web            |
| ServerWEB2Alexandro  | Servidor Web      | 192.168.2.3               | Web            |
| ServerNFSAlexandro   | NFS + PHP-FPM     | 192.168.3.1 / 192.168.2.4 | Backend        |
| ProxyBDAlexandro     | HAProxy MariaDB   | 192.168.4.1 / 192.168.3.2 | BD             |
| BD1Alexandro         | MariaDB           | 192.168.4.2               | BD             |
| BD2Alexandro         | MariaDB           | 192.168.4.3               | BD             |

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
* Reenvían las peticiones PHP al servidor NFS

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
