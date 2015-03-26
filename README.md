# Preflight

Very simple script to check for known error conditions and if they are found
print an error message with resolution instructions or a link to the JIRA 
tickets.

Not supported in any way but useful nevertheless...

# Usage
Just run the script:
`./preflight.sh`


# Examples

## Detecting Jira issues
```
[root@master puppet-preflight]# ./preflight.sh
ENTERPRISE-553 -- please chmod +rx /var/log
[root@master puppet-preflight]# chmod +rx /var/log
[root@master puppet-preflight]# ./preflight.sh
No known issues detected, safe to install Puppet Enterprise.  This script was last tested with 3.7.2
```

## Detecting existing PE installs
```
[root@master puppet-preflight]# ./preflight.sh 
Found Puppet Enterprise 3.8.0-rc0-281-gd05d353 at /opt/puppet
No known issues detected, safe to install Puppet Enterprise.  This script was last tested with 3.7.2
```

## Detecting multiple issues
```
[root@master puppet-preflight]# ./preflight.sh 
./preflight.sh: line 15: /opt/puppet/bin/puppet: Permission denied
A broken install of Puppet Enterprise was found at /opt/puppet  - maybe you need to delete it?
POSS config dir found at /etc/puppet - should be removed
Stale PE configuration dir found at /etc/puppetlabs - maybe you need to delete it?
*** PROBLEMS DETECTED ***
Please investigate the above issues before attempting to install Puppet Enterprise
```

# Requirements
* curl
* awk
* bash
