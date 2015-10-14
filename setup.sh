#!/usr/bin/env bash

# Load a configuration from secant.conf
source secant.conf

# Install Lynis
# https://github.com/CISOfy/lynis.git
mkdir -p /usr/local/lynis
wget -P ${lynis_directory} https://cisofy.com/files/lynis-${lynis_version}.tar.gz
tar xfvz ${lynis_directory}/lynis-${lynis_version}.tar.gz -C ${lynis_directory}
rm ${lynis_directory}/lynis-${lynis_version}.tar.gz

# Install Nmap
sudo apt-get install nmap -y