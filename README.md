# Preflight

Very simple script to check for known error conditions and if they are found
print an error message with resolution instructions or a link to the JIRA 
tickets.

Not supported in any way but useful nevertheless...

# Usage
Just run the script:
`./preflight.sh`


# Example
```
[root@master puppet-preflight]# ./preflight.sh
ENTERPRISE-553 -- please chmod +rx /var/log
[root@master puppet-preflight]# chmod +rx /var/log
[root@master puppet-preflight]# ./preflight.sh
No known issues detected, safe to install Puppet Enterprise
```

# Requirements
* curl
* awk
* bash
