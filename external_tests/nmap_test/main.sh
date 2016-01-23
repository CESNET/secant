#!/usr/bin/env bash
IP=$1
nmap -oX - $IP | python reporter.py
