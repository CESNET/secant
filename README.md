#secant
Security Cloud Assessment Tool

###Introduction
Secant is security assessment tool. Used to evaluate the security defenses of OS images uploaded by users of IaaS cloud. 

######How it works
The assessment process consists of performing a set of steps.

**Steps**

1. Create virtual machine from image and run it in isolated environment (without internet connection).

2. Run external tests. These is tests which do not need access to the system. For example port scanning.

3. Run internal tests. For this type of tests SSH connection is needed because they run on the virtual machine itself. As a consequence they are not run on Windows images.

4. Report status of security scan.

5. Make assessment using report and predefined rules.

During the entire assessment process details about the process are stored in a log file (path can be specified in conf/secant.conf). When the process is successfully ended, findings can be find in a report file and assessment results in a result file.

######Individual tests

**External tests**
- nmap_test - scan ports with [Nmap](https://nmap.org). Ports which should be closed can be specified in assessment.conf
- ssh_authentication_test - check if SSH password authentication is allowed. If yes, test ends unsuccessfully.  

**Internal tests**
- lynis_test - upload [Lynis](https://cisofy.com/lynis/) (security auditing tool) to a virtual machine. Lynis scans the system and generate a report. Which Lynis warnings or suggestions will be considered as critical, can be specified in conf/secant.conf. If some of these critical warnings or suggestions appear, test ends unsuccessfully. 
- pakiti_test - test the system against [Pakiti3](https://github.com/CESNET/pakiti3) to find packages with critical vulnerabilities. 


###Instalation
