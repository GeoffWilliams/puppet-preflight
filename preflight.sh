#!/bin/bash
#
# ===[Preflight installation checker for PE]===
CLEAN=true

# proxy detection
curl "http://www.google.com" --connect-timeout 10 --max-time 10 --silent --output /dev/null
if [ $? -ne 0 ] ; then
  echo "could not connect to google - is there a proxy server? see https://docs.puppetlabs.com/references/latest/configuration.html#httpproxyhost, you may have to set http_proxy and https_proxy environment variables to install.  PE installation requires internet access OR working configured yum repository"
  CLEAN=false
fi

# umask
if [ $(umask) != "0022" ] ; then
  echo "Please set your umask to 0022 before installing!"
  echo "MANY bugs caused by incorrect umask:  https://tickets.puppetlabs.com/issues/?jql=text%20~%20umask%20ORDER%20BY%20summary%20ASC"
  CLEAN=false
fi

# ENTERPRISE-532
# console fails to to render correctly due to incorrect mime types
if [ -f /etc/mime.types ] && [ $(awk /css/ /etc/mime.types |wc -l) -eq 0 ] ; then
  echo "ENTERPRISE-532 -- please reinstall (or remove) the mailcap package"
  CLEAN=false
fi


# ENTERPRISE-531
# Puppet Enterprise fails to install if /tmp mounted with the noexec option
if [ "$(mount | awk /noexec/)" != "" ] ; then
  echo "ENTERPRISE-351 -- filesystems mounted with noexec detected, please ensure /tmp is not mounted with the 'noexec' option"
  CLEAN=false
fi


#  Bug  ENTERPRISE-553  
# Puppet Enterprise fails to install if /var/log is not world readable and executable 
if [ $(stat -c '%a' /var/log) != "755" ] ; then
  echo "ENTERPRISE-553 -- please chmod +rx /var/log"
  CLEAN=false
fi


# Overall status
if [ $CLEAN = true ] ; then
  echo "No known issues detected, safe to install Puppet Enterprise"
else
  exit 1
fi
