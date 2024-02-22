# what i did for the project

## edit the /etc/hosts to use the correct hostname and fully qualified domain name
``` bash
sudo vim /etc/hosts
```
```
127.0.0.1	localhost
127.0.1.1	server1.ddp.is 	server1
192.168.100.10	server1.ddp.is 	server1
```
```
127.0.0.1	localhost
127.0.1.1	client1.ddp.is 	client1
192.168.100.10	server1.ddp.is 	server1
```
```
127.0.0.1	localhost
127.0.1.1	client2.ddp.is 	client2
192.168.100.10	server1.ddp.is 	server1
```

## change the hostanme using hostnamectl
``` bash
sudo hostnamectl set-hostname server1
sudo hostnamectl set-hostname client1
sudo hostnamectl set-hostname client2
```

## configure static ip on server1
``` bash
sudo vim /etc/netplan/01-network-manager-all.yaml
```
``` yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp7s0:
      addresses:
        - 192.168.100.10/24
```

## set up dhcp server on server1
``` sh
sudo apt install isc-dhcp-server
```
### add to dhcpd config
``` sh
sudo vim /etc/dhcp/dhcpd.conf
```
```
subnet 192.168.100.0 netmask 255.255.255.0 {
  range 192.168.100.11 192.168.100.254;
}
```
``` sh
sudo systemctl restart isc-dhcp-server
```
## configure networks on client 1 and 2
### client1
```
sudo vim /etc/netplan/01-network-manager-all.yaml
```
``` yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp7s0:
      dhcp4: yes
```
### client2
```
sudo vim /etc/sysconfig/network-scripts/ifcfg-eth1
```
```
DEVICE=eth1
NM_CONTROLLED-"no"
ONBOOT=yes
TYPE=Ethernet
BOOTPROTO=dhcp
GATEWAY=192.168.100.10
DNS1=192.168.100.10
```




