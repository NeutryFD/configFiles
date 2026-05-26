#/bin/bash

DNS_SERVER="192.168.1.110"
DNS_MAC="bc:24:11:a4:1d:14"
DNS_UP="ping -c 1 $DNS_SERVER > /dev/null 2>&1"
RESOLVE="nameserver $DNS_SERVER
options edns0 trust-ad
search home"

if eval $DNS_UP; then
	echo "$RESOLVE" > /etc/resolv.conf
else
	DNS_SERVER="127.0.0.1"
	echo "$RESOLVE" > /etc/resolv.conf

fi
