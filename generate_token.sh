#!/usr/bin/env bash

source secant.conf
export ONE_XMLRPC=$ONE_XMLRPC
oneuser login secant --cert /root/.secant/secant-cert.pem --key /root/.secant/secant-key.pem --x509 --force
