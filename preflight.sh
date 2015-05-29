#!/bin/bash
#
# ===[Preflight installation checker for PE]===
CLEAN=true

# The last version this tool was tested against
PE_RELEASE="3.8.0"

PE_DIR="/opt/puppet"
PE_CONF_DIR="/etc/puppetlabs"
POSS_CONF_DIR="/etc/puppet"
WORKING_PE=false
# install of puppet already exist?
if [ -d $PE_DIR ] ; then
  EXISTING_PE=$("${PE_DIR}/bin/puppet" --version)
  if [ $? -eq 0 ] ; then
    EXISTING_PE_VERSION=$(echo $EXISTING_PE | awk '{gsub(")","", $4); print $4}')
    echo "Found Puppet Enterprise ${EXISTING_PE_VERSION} at ${PE_DIR}"
    WORKING_PE=true
  else
    CLEAN=false
    echo "A broken install of Puppet Enterprise was found at ${PE_DIR} - maybe you need to delete it?"
  fi
fi

# other installs of puppet -eg from source/package
OTHER_INSTALLS=$(find / -type f -not -path "${PE_DIR}/*" -name puppet -executable -type f)
if [ "$OTHER_INSTALLS" != "" ] ; then
  echo "Non PE puppet executables found on system: (please remove them)"
  echo $OTHER_INSTALLS
  CLEAN=false
fi

# config dirs
if [ -d $POSS_CONF_DIR ] ; then
  echo "POSS config dir found at $POSS_CONF_DIR - should be removed"
  CLEAN=false
fi

if [ $WORKING_PE = false ] && [ -d $PE_CONF_DIR ]  ; then
  echo "Stale PE configuration dir found at ${PE_CONF_DIR} - maybe you need to delete it?"
  CLEAN=false
fi

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
  echo "ENTERPRISE-531 -- filesystems mounted with noexec detected, please ensure /tmp is not mounted with the 'noexec' option"
  CLEAN=false
fi


#  Bug  ENTERPRISE-553  
# Puppet Enterprise fails to install if /var/log is not world readable and executable 
if [ $(stat -c '%a' /var/log) != "755" ] ; then
  echo "ENTERPRISE-553 -- please chmod +rx /var/log"
  CLEAN=false
fi

# BUGS PE-9506, SERVER-592, PE-9973
# Jruby doesn't work on Debian/Ubuntu systems when libcrypt.so is not in the
# default library path
if [ ! -e "/usr/lib64" ] ; then
  echo "PE-9506, SERVER-592, PE-9973 -- please ensure libcrypt.so available under /usr/lib64, eg: ln -s /lib/x86_64-linux-gnu/ /usr/lib64"
  CLEAN=false
fi

# Overall status
if [ $CLEAN = true ] ; then
  echo "No known issues detected, safe to install Puppet Enterprise.  This script was last tested with ${PE_RELEASE}"
else
  echo "*** PROBLEMS DETECTED ***"
  echo "Please investigate the above issues before attempting to install Puppet Enterprise"
  exit 1
fi
