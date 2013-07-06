#!/bin/bash


if [ $# -lt 5 ]; then
  echo "Usage: `basename $0` IP NETMASK GATEWAY FQDN"
  exit 1
fi

IP=$1
NETMASK=$2
GATEWAY=$3
FQDN=$4

sed "s=@IP@=${IP}=g; s=@NETMASK@=${NETMASK}=g; s=@GATEWAY@=${GATEWAY}=g; s=@FQDN@=${FQDN}=g;" ../configs/esxi5-ks.template
