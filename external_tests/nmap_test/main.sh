#!/usr/bin/env bash
IP=$1
echo [`date +"%T"`] "### Nmap Report ###"
nmap $IP