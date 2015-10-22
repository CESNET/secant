#!/usr/bin/env bash
export ONE_XMLRPC=https://cloud.metacentrum.cz:6443/RPC2
oneuser login secant --cert /root/.secant/secant-cert.pem --key /root/.secant/secant-key.pem --x509 --force
