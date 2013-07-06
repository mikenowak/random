#!/bin/bash


if [ $# -lt 5 ]; then
  echo "Usage: `basename $0` REPO IP NETMASK GATEWAY FQDN"
  exit 1
fi

REPO=$1
IP=$2
NETMASK=$3
GATEWAY=$4
FQDN=$5

sed "s=@REPO@=${REPO}=g; s=@IP@=${IP}=g; s=@NETMASK@=${NETMASK}=g; s=@GATEWAY@=${GATEWAY}=g; s=@FQDN@=${FQDN}=g;" ../configs/esxi5-ks.template
