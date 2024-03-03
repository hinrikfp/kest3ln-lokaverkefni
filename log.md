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
```
vim addusers.sh
```
``` bash
while IFS="," read -r full_name first_name last_name username email department ID
do 
	if [ -z "$full_name" ] || [ -z "$first_name" ] || [ -z "$last_name" ] || [ -z "$username" ] || [ -z "$email" ] || [ -z "$department" ] || [ -z "$ID" ]; then
		continue
	fi
	echo "$full_name" "$first_name" "$last_name" "$username" "$email" "$department" "$ID"
	getent group "$department" || groupadd "$department"
	useradd -b /home/"$department" -m -g "$department" "$username"
done < <(tail -n +2 Linux_Users.csv)
```
```
chmod +x addusers.sh
sudo bash addusers.sh
```

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
## backup home directory weekly
```
crontab -e
```
```
59 23	* * 5	tar -zcf /var/backups/home.tgz /home/
```
## set up ntp server using chrony
```
sudo apt install chrony
sudo vim /etc/chrony/chrony.conf
```
add this line to configuration if default set up
```
allow 192.168.100.0/24
```
```
sudo ufw allow ntp
```
### client1
```
sudo apt install chrony
sudo vim /etc/chrony/chrony.conf
```
add line
```
server 192.168.100.10
```
test with chronyc
```
chronyc sources
```
### client2
```
sudo vim /etc/chrony.conf
```
add line
```
server 192.168.100.10
```
test with chronyc
```
chronyc sources
```
## setting up rsyslog
```
sudo vim /etc/rsyslog.conf
```
uncomment or add these lines
```
module(load="imudp")
input(type="imudp" port="514")
```
uncomment and change these lines
```
module(load="imtcp")
input(type="imtcp" port="50514")
```
```
sudo ufw allow 514/udp
sudo ufw allow 50514/tcp
```
```
sudo vim /etc/rsyslog.conf
```
add these lines under global directives
```
AllowedSender UDP, 192.168.100.0/24, *.ddp.is 
$AllowedSender TCP, 192.168.100.0/24, *.ddp.is
```
```
sudo ufw allow from 192.168.100.0/24 to any port 514 proto udp
sudo ufw allow from 192.168.100.0/24 to any port 50514 proto tcp

```
```
sudo vim /etc/rsyslog.conf
```
add these lines to /etc/rsyslog.conf
```
$template RemInputLogs, "/var/log/remotelogs/%FROMHOST-IP%/%PROGRAMNAME%.log"
*.* ?RemInputLogs
```
test config
```
sudo rsyslogd -f /etc/rsyslog.conf -N1
```
### configure logging to the server on the clients
both clients:
```
sudo vim /etc/rsyslog.conf
```
```
# send logs to remote syslog server over UDP
*.* @192.168.100.10:514  
```
```
sudo systemctl restart rsyslog
```
test logging  
clients:
```
logger -t TEST -p mail.err 'testing logger'
```
server:
```
sudo ls /var/log/remotelogs/
```

## configure mail
### install postfix
```
sudo apt install postfix
```
select "internet site"
type "ddp.is"

### install dovecot
```
sudo apt install dovecot-imapd dovecot-pop3d
sudo systemctl restart dovecot
```
### install roundcube
```
wget https://github.com/roundcube/roundcubemail/releases/download/1.6.6/roundcubemail-1.6.6-complete.tar.gz
tar tar xvf roundcubemail-1.6.6-complete.tar.gz 
sudo mkdir /var/www/
sudo mv roundcubemail-1.6.6 /var/www/roundcube
cd /var/www/roundcube/
sudo chown www-data:www-data temp/ logs/ -R
```
### install php extensions
```
sudo apt install software-properties-common
sudo add-apt-repository ppa:ondrej/php
sudo apt update
sudo apt install php-net-ldap2 php-net-ldap3 php-imagick php8.1-common php8.1-gd php8.1-imap php8.1-mysql php8.1-curl php8.1-zip php8.1-xml php8.1-mbstring php8.1-bz2 php8.1-intl php8.1-gmp php8.1-redis
```
### set up roundcube mysql database
```
sudo mysql -u root
CREATE DATABASE roundcube DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER roundcube@localhost IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON roundcube.* TO roundcube@localhost;
flush privileges;
exit;
sudo mysql roundcube < /var/www/roundcube/SQL/mysql.initial.sql
```
### install and configure apache
```
sudo apt install apache2
sudo nvim /etc/apache2/sites-available/server1.ddp.is.conf
sudo a2ensite server1.ddp.is.conf
sudo systemctl reload apache2
```
það var eitthvað vandamál með PHP þannig að ég náði ekki að klára að setju upp Roundcube

## printers




