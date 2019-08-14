#!/bin/sh

/opt/quest/bin/vastool timesync
for badvalue in Administrator Administrato root User '' `perl -e 'print "A"x2048'` `perl -e 'print "%x"x2048'` '*' a
do
	/opt/quest/bin/vastool attrs -u "${badvalue}"
	/opt/quest/bin/vastool delete user "${badvalue}"
	/opt/quest/bin/vastool info id -u "${badvalue}"
	/opt/quest/bin/vastool info adsecurity -u "${badvalue}"
	/opt/quest/bin/vastool isvas -p user "${badvalue}"
	/opt/quest/bin/vastool inspect libdefaults "${badvalue}"
	/opt/quest/bin/vastool inspect "${badvalue}" default_realm
	/opt/quest/bin/vastool inspect "${badvalue}" "${badvalue}"
	/opt/quest/bin/vastool list user "${badvalue}"
	/opt/quest/bin/vastool list group "${badvalue}"
	/opt/quest/bin/vastool load "${badvalue}"
	/opt/quest/bin/vastool nss getpwnam "${badvalue}"
	/opt/quest/bin/vastool nss getpwuid "${badvalue}"
	/opt/quest/bin/vastool nss getspnam "${badvalue}"
	/opt/quest/bin/vastool nss getgrnam "${badvalue}"
	/opt/quest/bin/vastool nss getgroups "${badvalue}"
	/opt/quest/bin/vastool schema -h "${badvalue}" list
	/opt/quest/bin/vastool schema -h "${badvalue}" detect
	/opt/quest/bin/vastool schema -h "${badvalue}" cache
	/opt/quest/bin/vastool search "${badvalue}"
	/opt/quest/bin/vastool service list "${badvalue}"
	/opt/quest/bin/vastool setattrs "${badvalue}" b c
	/opt/quest/bin/vastool setattrs a "${badvalue}" c
	/opt/quest/bin/vastool setattrs a b "${badvalue}"
	/opt/quest/bin/vastool setattrs "${badvalue}" "${badvalue}" c
	/opt/quest/bin/vastool setattrs a "${badvalue}" "${badvalue}"
	/opt/quest/bin/vastool setattrs "${badvalue}" "${badvalue}" "${badvalue}"
	/opt/quest/bin/vastool user checklogin "${badvalue}"
	/opt/quest/bin/vastool user checkaccess "${badvalue}"
	/opt/quest/bin/vastool user checkconflict "${badvalue}"
	/opt/quest/bin/vastool -u "${badvalue}" unjoin -f
done
/opt/quest/bin/vastool -u Administrator join 3rd-party.example.org
/opt/quest/bin/vastool timesync
/opt/quest/bin/vastool flush
/opt/quest/bin/vastool info site
oopt/quest/bin/vastool info domain
/opt/quest/bin/vastool info domain-dn
/opt/quest/bin/vastool info forest-root
/opt/quest/bin/vastool info forest-root-dn
/opt/quest/bin/vastool info domains
/opt/quest/bin/vastool info domains-dn
/opt/quest/bin/vastool info filelocks
/opt/quest/bin/vastool info servers
/opt/quest/bin/vastool info toconf a
/opt/quest/bin/vastool info adsecurity
/opt/quest/bin/vastool info acl
/opt/quest/bin/vastool info cldap
/opt/quest/bin/vastool info ipv6
/opt/quest/bin/vastool join 3rd-party.example.org
/opt/quest/bin/vastool license
/opt/quest/bin/vastool list users
/opt/quest/bin/vastool list users-allowed
/opt/quest/bin/vastool list users-denied
/opt/quest/bin/vastool list groups
/opt/quest/bin/vastool list netgroups
/opt/quest/bin/vastool list negcache
/opt/quest/bin/vastool load /etc/issue
/opt/quest/bin/vastool nss getpwuid 0
/opt/quest/bin/vastool nss getpwuid -1
/opt/quest/bin/vastool nss getpwent
/opt/quest/bin/vastool nss getgrent
/opt/quest/bin/vastool schema list
/opt/quest/bin/vastool schema detect
/opt/quest/bin/vastool schema cache
/opt/quest/bin/vastool schema -h localhost list
/opt/quest/bin/vastool schema -h localhost detect
/opt/quest/bin/vastool schema -h localhost cache
/opt/quest/bin/vastool status
/opt/quest/bin/vgptool config
/opt/quest/bin/vgptool listgpc
/opt/quest/bin/vgptool listgpt
/opt/quest/bin/vgptool rsop
/opt/quest/bin/vgptool clean
/opt/quest/bin/uptool info
/opt/quest/bin/uptool list
/opt/quest/bin/uptool list up
/opt/quest/bin/uptool list ug
/opt/quest/bin/uptool list g
/opt/quest/bin/uptool membership
/opt/quest/bin/uptool membership up
/opt/quest/bin/uptool membership ug
/opt/quest/bin/uptool membership g
