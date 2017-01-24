#!/bin/bash
#
# ===[Preflight installation checker for PE]===
CLEAN=true

# The last version this tool was tested against
PE_RELEASE="2016.4.0"

PE_DIR="/opt/puppetlabs"
PE_CONF_DIR="/etc/puppetlabs"
POSS_CONF_DIR="/etc/puppet"
WORKING_PE=false
# install of puppet already exist?
if [ -d $PE_DIR ] ; then
  EXISTING_PE=$("${PE_DIR}/puppet/bin/puppet" --version)
  if [ $? -eq 0 ] ; then
    EXISTING_PE_VERSION=$(cat "${PE_DIR}/server/pe_version"||echo "BROKEN")
    echo "Found Puppet Enterprise ${EXISTING_PE_VERSION} at ${PE_DIR}"
    WORKING_PE=true
  else
    CLEAN=false
    echo "A broken install of Puppet Enterprise was found at ${PE_DIR} - maybe you need to delete it?"
  fi
fi

# other installs of puppet -eg from source/package
OTHER_INSTALLS=$(find / -type f -not -path "/etc/**" -not -path "${PE_DIR}/**" -name puppet -executable -type f)
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


#  Bug  ENTERPRISE-553
# Puppet Enterprise fails to install if /var/log is not world readable and executable

# permissions we want r-xr-xr-x or greater
PERMS_WANT=0555

# permissions on the directory
PERMS_FILE=0$(stat -c '%a' /var/log)

# bitwise and
PERMS_HAVE=$(( $PERMS_FILE & $PERMS_WANT ))

# convert back into octal (my eyes...)
PERMS_HAVE=0$(printf %o $PERMS_HAVE)

if [[ "$PERMS_HAVE" != "$PERMS_WANT" ]] ; then
  echo "ENTERPRISE-553 -- please chmod +rx /var/log"
  CLEAN=false
fi

# Check CPU count
cpu_cores=$(grep -c processor /proc/cpuinfo)
if [[ $cpu_cores -lt 4 ]] ; then
  echo "A Puppet master should have at least 4 CPU cores. Found ${cpu_cores}"
  echo "Puppet Enterprise hardware requirements: https://docs.puppet.com/pe/latest/sys_req_hw.html#hardware-requirements"
  CLEAN=false
fi

# Check RAM
total_ram_kB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
if [[ $total_ram_kB -lt 8388608 ]] ; then
  echo "A Puppet master should have at least 8 GB of ram. Found $(( total_ram_kB / 1024 / 1024 )) GB"
  echo "Puppet Enterprise hardware requirements: https://docs.puppet.com/pe/latest/sys_req_hw.html#hardware-requirements"
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
