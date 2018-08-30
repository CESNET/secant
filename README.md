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

- `open_ports` - The probe lists open ports exposed by the machine. The probes doesn't consider any open port as insecure, it's used to check the machine is available over the network and provides a list of services that is used by other probes.
- `ntp_amp` - Certain configurations of the NTP service makes it possible for the attacker to mount an amplification attack that greatly increases the efficiency of the attack. Since the traffic originates from the NTP server it might hit badly the service owner. The probe checks that the risky configuration is not available to the Internet.
- `ssh_auth` - Password-based authentication is prone to a range of attacks, it's recommended to be disabled.
- `ssh_passwd` - The probe performs a dictionary attack over SSH and check a number of combinations of known passwords and usernames. The test resembles malicious activities that are very common on the Internet.
- `lynis_test` - Lynis is a tool that checks a number of security characteristics of the machine. The probe runs the Lynis command and returns the results. The outcome isn't interpreted and sometimes may suggest precautions that are out of scope for the purpose of the tested machine. The machine must enable remote access in order to run the probe.
- `pakiti_test` - The probe uses the EGI Pakiti service to detect packages that haven't been updated. If they expose a vulnerability tagged important for EGI, the probes returns with an error. The machine must enable remote access in order to run the probe.
