# Secant
Security Cloud Assessment Tool

### Introduction
Secant is security assessment tool. Used to evaluate the security defenses of OS images uploaded by users of IaaS cloud.

###### How it works
The assessment process consists of performing a set of steps.

**Steps**

1. Create virtual machine from image and run it in isolated environment (without internet connection).

2. Run set of probes.

3. Report status of security scan.

4. Make assessment using report and predefined rules.

During the entire assessment process details about the process are stored in a log file (path can be specified in `secant.conf`). When the process is successfully ended, findings can be find in a report file and assessment results in a result file.

###### Probes

- `open_ports` - scan ports with [Nmap](https://nmap.org).
- `ntp_amp` - check if machine is vulnerable to network time protocol amplification attack.
- `ssh_auth` - check if SSH password authentication is allowed. If yes, test ends unsuccessfully.
- `ssh_passwd` - if SSH password authentication is allowed, probe is trying to detect weak passwords by dictionary attack using tool [Hydra](https://github.com/vanhauser-thc/thc-hydra). Hydra requires lists of users and passwords.
- `lynis_test` - upload [Lynis](https://cisofy.com/lynis/) (security auditing tool) to a virtual machine. Lynis scans the system and generate a report. Which Lynis warnings or suggestions will be considered as critical, can be specified in secant.conf. If some of these critical warnings or suggestions appear, test ends unsuccessfully.
- `pakiti_test` - test the system against [Pakiti3](https://github.com/CESNET/pakiti3) to find packages with critical vulnerabilities.

Probes depend on each other so their order is important. For example all probes are reading result of `open_ports`.

### Instalation
###### Preparing Secant Host
Secant host manage all assessment processes.  Secant is supposed to run on a Debian operating system and have two network interfaces. First interface with public ip address is used for internet connection and second interface with private ip is connected to the isolated enviroment where tested images will be instantiated.

You'll also need to create secant user in IaaS with enough permissions to instantiate templates from images which are waiting for analysis. You also need to ensure that secant user is able to access IaaS throgh command line. Instructions for MetaCloud can be found [here](https://wiki.metacentrum.cz/wiki/MetaCloud_access_through_command_line).

###### Installing Secant
Before proceeding on configuring Secant, you'll need to install some required software and libraries. For this purpose run `install.sh` script. Before running it fill in `lynis_version` and `lynis_directory` in `secant.conf`. It is recommended to use the latest Lynis version.

###### Configuration
- `secant.conf`: for configuring general settings. Also defines the order in which probes are running. The default configuration is expected in `/etc/secant/secant.conf`, an alterative location can be specified using the `SECANT_CONFIG_DIR` environment variable.
```
# The current stable version of Lynis which you want to download.
lynis_version=2.2.0

# Specify the directory where Lynis will be stored.
lynis_directory=/usr/local/lynis

# Specify the path to your log file.
log_file=/var/log/secant.log

# Specify the path to the secant user certificate. Make sure this path is correct.
CERT_PATH=

# Specify the path to the secant key. Make sure this path is correct.
KEY_PATH=

# Debug, true or false
DEBUG=true

# If set to 'yes' a template will be removed once it's been tested
DELETE_TEMPLATES="yes"

# Version of current test set
VERSION=1.0

# Directory to store image lists retrieved from AppDB
IMAGE_LIST_DIR=/var/spool/secant

# URL pointing to IMAGE_LIST_DIR
IMAGE_LIST_URL=https://example.org/secant/

# Directory to keep state information
STATE_DIR=/var/lib/secant

# The root of secant installation
SECANT_PATH=/opt/secant

# List of probes
SECANT_PROBES=open_ports,ntp_amp,ssh_auth,ssh_passwd,lynis_test,pakiti_test
```

- `probes.conf`: for configuring probes. The default configuration is expected in `/etc/secant/probes.conf`, an alterative location can be specified using the `SECANT_CONFIG_DIR` environment variable.
```
#path to pakiti client
SECANT_PROBE_PAKITI_CLIENT="/opt/pakiti-client/pakiti-client"

#pakiti url
SECANT_PROBE_PAKITI_URL=https://pakiti.cesnet.cz/egi/feed/

#path to run lynis
SECANT_PROBE_LYNIS=/usr/local/lynis/lynis

#path to directory with list of users and passwords for hydra dictionary attack
SECANT_PROBE_HYDRA=/etc/secant
```
###### Using Secant
Use `./secant.sh` to start the program. After starting Secant starts searching for the images that are waiting for analysis. Once the process is complete, Secant delete image and template from the queue.
