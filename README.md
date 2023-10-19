# LinikatzV2
LinikatzV2 is a bash script based on the Linikatz tool developed by time-machine (https://github.com/CiscoCXSecurity/linikatz).
It allows post-exploitation tasks on UNIX computers joined to Active Directory, using various methods for credential mining.

This tool needs **root privileges** to be run on the host system.

It allows extraction of :
- Hashed stored in files for offline connection (SHA-512 format)
- Kerberos tickets (user & machine)
- Clear passwords in RAM
- NTLM machine hash
- AES-128 & AES-256 machine keys

Optional :
- Configuration files (SSSD, VAS, etc)

Some of these actions may not produce results. Typically, the presence of hashes and clears in RAM depends on a user's connection to the UNIX system.

## Usage

```
$ sudo ./linikatzV2.sh
```
Various options are available :

- -c | --conf-files : Dumps configuration files.
- --hash-output=file.txt : Allows you to choose the name of the output file containing the hashes.
- -n | -no-file : Removes the process dump files, etc.
- -k | --kerberos-tickets : Create a copy of the Kerberos tickets found.
