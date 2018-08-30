# Secant
Security Cloud Assessment Tool

### Instalation
##### Preparing Secant Host
Secant host manage all assessment processes.  Secant is supposed to run on a Debian operating system and have two network interfaces. First interface with public ip address is used for internet connection and second interface with private ip is connected to the isolated enviroment where tested images will be instantiated.

You'll also need to create secant user in IaaS with enough permissions to instantiate templates from images which are waiting for analysis. You also need to ensure that secant user is able to access IaaS throgh command line. Instructions for MetaCloud can be found [here](https://wiki.metacentrum.cz/wiki/MetaCloud_access_through_command_line).

##### Installing Secant
Before proceeding on configuring Secant, you'll need to install some required software and libraries. For this purpose run `install.sh` script. Before running it fill in `lynis_version` and `lynis_directory` in `secant.conf`. It is recommended to use the latest Lynis version.

##### Configuration
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

# Directory for templates
CLOUDKEEPER_TEMPLATES_DIR=/var/lib/secant/one-templates/

# IP address and port for cloudkeeper-one
CLOUDKEEPER_ENDPOINT="127.0.0.1:60051"

# Lock file for argo_consume
ARGO_LOCK_FILE=/var/run/argo_consume.lock
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

# List of probes
SECANT_PROBES=open_ports,ntp_amp,ssh_auth,ssh_passwd,lynis_test,pakiti_test
```
##### Using Secant
Use `./secant.sh` to start the program. After starting Secant starts searching for the images that are waiting for analysis. Once the process is complete, Secant delete image and template from the queue.

##### Adding new probes
- Add probe name to `probes.conf` variable `SECANT_PROBES`.
- Create directory in `SECANT_PATH/probes` with probe name.
- Create 2 files in directory:
    - probe.yaml for decription of probe(example below).
    - main for executing probe.

Main output:
- 1\. line - status(***OK/ERROR/SKIPPED***)
- 2\. line - summary
- other lines - details

If main ends with return code other than "0", status of probe is ***INTERNAL_FAILURE***. Summary and details are filled from stderr.
