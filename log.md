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

## configure dns bind9
``` sh
sudo apt install bind9 bind9utils bind9-docs
```
``` sh
sudo vim /etc/default/named
```
```
OPTIONS="-u bind -4"
```
```
sudo systemctl restart bind9
```
``` sh
sudo vim /etc/bind/named.conf.options
```
``` 
acl "trusted" {
	192.168.100.10;
	192.168.100.0/24;
	localhosts;
	localnets;
}

options {
	directory "/var/cache/bind";

	recursion yes;
	allow-recursion { trusted; };
	listen-on {192.168.100.10; };
	allow-transfer { none; };

	forwarders {
		1.1.1.1;
		8.8.8.8;
	};

	dnssec-validation auto;

	listen-on-v6 { any; };
};
```
```
sudo vim /etc/bind/named.conf.local
```
```
zone "ddp.is" {
	type primary;
	file "/etc/bind/zones/db.ddp.is";
};

zone "100.168.192.in-addr.arpa" {
	type primary;
	file "/etc/bind/zones/db.192.168.100";
};
```
### configuring zones
```
sudo mkdir /etc/bind/zones
sudo cp /etc/bind/db.local /etc/bind/zones/db.ddb.is
sudo vim /etc/bind/zones/db.ddp.is
```
```
STTL	604800
@	IN	SOA	server1.ddp.is. admin.ddp.is. (
			      3		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
; name servers -ns records
	IN	NS	server1.ddp.is.

; namer servers A records
server1.ddp.is.		IN	A	192.168.100.10

; host A records
client1.ddp.is		IN 	A	192.168.100.11
client2.ddp.is		IN	A	192.168.100.12
```
```
sudo cp /etc/bind/db.127 /etc/bind/zones/db.192.168.100
sudo vim /etc/bind/zones/db.192.168.100
```
```
; BIND reverse data file for local loopback interface
;
$TTL	604800
@	IN	SOA	server1.ddp.is. admin.ddp.is. (
			      3		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
; name server - NS records
	IN	NS	server1.ddp.is.
; PTR records
10	IN	PTR	server1.ddp.is.	; 192.168.100.10
11	IN	PTR	client1.ddp.is.	; 192.168.100.11
12	IN	PTR	client2.ddp.is.	; 192.168.100.12
```
```
sudo named-checkconf
sudo named-checkzone ddp.is /etc/bind/zones/db.ddp.is
sudo named-checkzone 100.168.192 /etc/bind/zones/db.192.168.100
```
```
sudo systemctl restart bind9
sudo ufw allow Bind9
```
## create and run useradd script
TODO

## install and configure mariadb/mysql
```
sudo apt install mariadb-server
sudo systemctl start mariadb.service
sudo mysql_secure_installation
```
```
sudo mariadb
```
``` sql
GRANT ALL ON *.* TO 'admin'@'localhost' IDENTIFIED BY 'password123' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit;
```
## create Human Resources database
```
vim HRdb.sql
```
``` sql
create database if not exists HumanResources;
use HumanResources;

create table Jobs
(
        ID int auto_increment,
        title varchar(150),
        minSalary int,
        maxSalary int,
        constraint PK primary key(ID)
);

create table Employees
(
        kennitala char(10),
        firstname varchar(75),
        lastname varchar(75),
        email varchar(150),
        phoneNumber varchar(12),
        hireDate date,
        salary int,
        job int,
        constraint job_FK foreign key(job)references Jobs(ID),
        constraint PK primary key(kennitala)
);

create table Locations
(
        ID int unique,
        city varchar(150),
        address varchar(150),
        zipCode int,
        constraint PK primary key(ID)
);

create table Departments
(
        ID int unique,
        departmentName varchar(100),
        manager char(10),
        location int,
        constraint manager_FK foreign key(manager)references Employees(kennitala),
        constraint location_FK foreign key(location)references Locations(ID),
        constraint PK primary key(ID)
);
```
```
mariadb -u admin -p
source /home/hinrik/HRdb.sql
```


