#secant
Security Cloud Assessment Tool

###Introduction
Secant is security assessment tool. Used to evaluate the security defenses of OS images uploaded by users of IaaS cloud. 

######How it works
The assessment process consists of performing a set of steps.

**Steps**

1. Create virtual machine from image and run it in isolated environment (without internet connection).

2. Run external tests. These are tests which do not need access to the system. For example port scanning.

3. Run internal tests. For this type of tests SSH connection is needed because they run on the virtual machine itself. As a consequence they are not run on Windows images.

4. Report status of security scan.

5. Make assessment using report and predefined rules.

During the entire assessment process details about the process are stored in a log file (path can be specified in `secant.conf`). When the process is successfully ended, findings can be find in a report file and assessment results in a result file.

######Individual tests

**External tests**
- `nmap_test` - scan ports with [Nmap](https://nmap.org). Ports which should be closed can be specified in `conf/assessment.conf`
- `ssh_authentication_test` - check if SSH password authentication is allowed. If yes, test ends unsuccessfully.  

**Internal tests**
- `lynis_test` - upload [Lynis](https://cisofy.com/lynis/) (security auditing tool) to a virtual machine. Lynis scans the system and generate a report. Which Lynis warnings or suggestions will be considered as critical, can be specified in secant.conf. If some of these critical warnings or suggestions appear, test ends unsuccessfully. 
- `pakiti_test` - test the system against [Pakiti3](https://github.com/CESNET/pakiti3) to find packages with critical vulnerabilities. 

###Instalation
######Preparing Secant Host
Secant host manage all assessment processes.  Secant is supposed to run on a Debian operating system and have two network interfaces. First interface with public ip address is used for internet connection and second interface with private ip is connected to the isolated enviroment where tested images will be instantiated. 

You'll also need to create secant user in IaaS with enough permissions to instantiate templates from images which are waiting for analysis. You also need to ensure that secant user is able to access IaaS throgh command line. Instructions for MetaCloud can be found [here](https://wiki.metacentrum.cz/wiki/MetaCloud_access_through_command_line).

######Installing Secant
Before proceeding on configuring Secant, you'll need to install some required software and libraries. For this purpose run `install.sh` script. Before running it fill in `lynis_version` and `lynis_directory` in `secant.conf`. It is recommended to use the latest Lynis version.  

######Configuration
Secant has two main configuration files:
- `secant.conf`:for configuring general settings. The default location is `/etc/secant/secant.conf', an alterative location can be specified using the `SECANT_CONFIG' environment variable.
```
# The current stable version of Lynis which you want to download.
lynis_version=2.1.1

# Specify the directory where Lynis will be stored.
lynis_directory=/usr/local/lynis

# Specify the directory where reports and results will be stored.
reports_directory=/var/log/secant-reports

# Specify the path to your log file.
log_file=/var/log/secant.log

# Enviroment variable
ONE_XMLRPC=https://cloud.metacentrum.cz:6443/RPC2

# Specify the path to the secant user certificate. Make sure this path is correct.
CERT_PATH=/root/.secant/secant-cert.pem

# Specify the path to the secant key. Make sure this path is correct.
KEY_PATH=/root/.secant/secant-key.pem
```
- `assessment.conf`:for configuring individual tests options
```
[NMAP_TEST]
# List of ports which should be closed.
Ports: 53, 19, 123, 161

[LYNIS_TEST]
# IDs of Lynis warnings and suggestions separated by commas.
# For example: NETW-2704, SSH-7412...
Warnings:
Suggestions:
```
######Using Secant
Use `./secant.sh` to start the program. After starting Secant starts searching for the images that are waiting for analysis. Once the process is complete, Secant delete image and template from the queue. 
