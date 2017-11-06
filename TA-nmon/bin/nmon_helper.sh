#!/bin/sh

# set -x

# Program name: nmon_helper.sh
# Purpose - nmon sample script to start collecting data with a 1mn interval refresh
# Author - Guilhem Marchand
# Disclaimer:  this provided "as is".  
# Date - June 2014

# 2015/05/09, Guilhem Marchand: Rewrite of main program to fix main common troubles with nmon_helper.sh, be simple, effective
# 2015/05/11, Guilhem Marchand: 
#										- Hotfix, improved process identification (All OS)
#										- Improved AIX options management (AIX options can now fully be managed by nmon.conf, corrected NFS V4 options which was incorrectly verified)
# 2015/05/14, Guilhem Marchand: Linux and Solaris corrections and improvements
#										- Linux max default devices missing (in case of nmon.conf not being sourced)
#										- Use a splunktag for process identification for Linux and Solaris hosts
#										- New Linux system identification to be used with embedded nmon binaries
# 2015/05/14, Guilhem Marchand: 
#										- AIX improvements: If not running topas-nmon, identification may fail, use the splunktag for non topas-nmon instance 
#										- Linux Ubuntu update: added binaries support for older releases
# 2015/06/24, Guilhem Marchand:
#										- All OS: Code improvements to prevent launching multiple nmon instances
# 2015/06/28, Guilhem Marchand:
#										- hotfix for nmon instances duplication: To prevent trouble at Splunk startup at boot time, the nmon_helper.sh uses now the -p option for nmon (AIX, Linux)
#										to retrieve the pid of the launched nmon instance
# 2015/07/08, Guilhem Marchand:
#										- hotfix for nmon instances duplication: Some cases may still lead to multiplicative processes, code improvements will prevent this
#										- hotfix for SUSE Linux: typo error leads to fail identifying best binaries for SUSE clients
# 2015/07/27, Guilhem Marchand:
#										- hotfix for using the PA-nmon to generate Performance data in standalone indexers
# 2015/07/29, Guilhem Marchand:
#										- hotfix for AIX, non protected grep generates -p option to be duplicated and error message in splunkd
# 2015/08/09, Guilhem Marchand: Manage gaps in data due to the time required for nmon to collect data when the current iterations ends:
#										- Estimate time in epoch when the current iteration will end
#										- Start a new nmon process 4 minutes before the current ends to let the new process time to start collecting
#										- Duplicated events management is operated by nmon2csv converters
# 2015/10/14, Guilhem Marchand:         - Use $SPLUNK_HOME/var/run/nmon for temp directory instead of /tmp
#                                       - Removed deactivation of CPUnn for Solaris, Manage UARG Solaris collection (new with Sarmon 1.11)
# 2015/11/11, Guilhem Marchand:         - sarmon binaries are now stored in a dedicated directory under bin
# 2015/12/11, Guilhem Marchand:         - path changes introduced with release 1.3.11 can generates duplicated processes due to ps truncation limits
# 2015/12/29, Guilhem Marchand:         - Evolution to manage sh cluster deployment: prevents text file busy error during bundle publication by running binaries from var instead of app directory
# 2016/02/13, Guilhem Marchand:         - Error in SUSE Linux identification over /etc/SuSE-release (bad pattern)
# 2016/02/14, Guilhem Marchand:         - Support for Archlinux with embedded binaries (x86 & x86_64)
# 2016/04/12, Guilhem Marchand:         - centOS OS and version detection if no os-release available (https://github.com/guilhemmarchand/nmon-for-splunk/issues/31)
# 2016/04/16, Guilhem Marchand:         - Linux binaries management - cp alias on some systems prevents binaries cache upgrade to proceed #32
# 2016/04/23, Guilhem Marchand:         - Improve the PID file age determination by switching from Perl to Python command depending on interpreter available
# 2016/05/19, Guilhem Marchand:         - Fix some situation were the nmon bin in path could be ignored
# 2016/05/31, Guilhem Marchand:         - AIX: Collect in default SEA and WLM stats (-O and -W options)
# 2016/06/12, Guilhem Marchand:         - Linux: Managed unlimited capturation for processes and disks
# 2016/07/11, Guilhem Marchand:         - Linux: Manage the bytes order system to identify if running in big or little endian
# 2016/07/12, Guilhem Marchand:         - Store linux binaries in a tgz archive file that be uncompressed if required
# 2016/07/16, Guilhem Marchand:         - ARM support
# 2016/07/25, Guilhem Marchand:         - Prevent tar error on Solaris OS
# 2016/07/30, Guilhem Marchand:         - The core app does not contain anymore any objects related to data generation
# 2016/07/30, Guilhem Marchand:         - Splunk certification requires $SPLUNK_HOME/var/log/ for files generation
# 2016/08/02, Guilhem Marchand:         - Manage the TA-nmon_selfmode
# 2016/08/13, Guilhem Marchand:         - typo in stale word #7
# 2016/08/31, Guilhem Marchand:         - Feature request - Linux_unlimited_capture improvement #9
# 2016/12/28, Guilhem Marchand:         - Implementation of Linux extended disk statistics
#                                       - Allow configuring custom settings in /etc/nmon.conf on a per server basis
# 2017/01/05, Guilhem Marchand:         - Correction for generic builds calling ARCH instead of ARCH_NAME
# 2017/02/10, Guilhem Marchand:         - Prevents failure for Nmon Linux with disk group on older Nmon releases
#                                       - Identification failure for Fedora OS
# 2017/02/25, Guilhem Marchand:         - Linux NFS option is not recognised (broken update)
#                                       - Linux unlimited capture custom value is not recognised (broken update)
# 2017/02/26, Guilhem Marchand:         - Potential redirection issue
#                                       - Avoid bc utilization and check unlimited linux capture type rather than range
# 2017/03/11, Guilhem Marchand:         - Lowering the CPU footprint: Write to FIFO files for AIX and Linux OS
# 2017/03/18, Guilhem Marchand:         - Implement the nmon external feature
# 2017/03/24, Guilhem Marchand:         - Be Python version restrictive for the fifo_reader choice
#                                       - prevent AIX error messages related to LIBPATH and rpm
#                                       - PowerLinux binaries identification failures
# 2017/03/29, Guilhem Marchand:         - nmon command not correctly displayed in nmon_helper.sh output
# 2017/03/30, Guilhem Marchand:         - AIX issue with nmon_external
# 2017/03/30, Guilhem Marchand:         - AIX issue with nmon_external (act II !)
# 2017/04/02, Guilhem Marchand:         - Update path discovery
# 2017/04/02, Guilhem Marchand:         - Solaris new sarmon release is fifo compatible
# 2017/04/07, Guilhem Marchand:         - New sarmon for Solaris on Sparc is not ready, avoid starting this version for now
# 2017/04/16, Guilhem Marchand:         - Fix nmon.conf formatting issue when deployed on search heads in SHC
# 2017/04/29, Guilhem Marchand:
#                                       - Fix AIX compatibility issue with old topas-nmon not accepting the -y option
# 2017/05/16, Guilhem Marchand:
#                                       - Allows activating / deactivating nmon external generation within nmon.conf
# 2017/05/22, Guilhem Marchand:
#                                       - Allows activating / deactivating fifo mode
# 2017/05/24, Guilhem Marchand:
#                                       - Bad variable name introduced in 1.3.47 changes
# 2017/06/04, Guilhem Marchand:
#                                       - Manage nmon external data in a dedicated file
# 2017/06/10, Guilhem Marchand:
#                                       - Manage nmon external header in a dedicated file
# 2017/06/14, Guilhem Marchand:
#                                       - Prevents spawning multiple nmon external instances in case of unexpected issue
#                                         this issue has been reported in some weired cases on AIX
# 2017/06/14, Guilhem Marchand:
#                                       - specify explicit date format to prevent time zone issues
# 2017/06/24, Guilhem Marchand:
#                                       - better management for nmon external snap instances multiplication
# 2017/06/26, Guilhem Marchand:
#                                       - review interpreter choice for the fifo start (AIX default to Perl)
# 2017/07/02, Guilhem Marchand:
#                                       - Linux issue: detection of default/nmon.conf rewrite required is incorrect
# 2017/07/06, Guilhem Marchand:
#                                       - AIX - Better management of compatibility issue with topas-nmon not supporting the -y option #43
# 2017/07/13, Guilhem Marchand:
#                                       - AIX - Better management of compatibility issue with topas-nmon not supporting the -y option #43
#                                       - AIX - fix repeated and not justified pid file removal message
#                                       - ALL OS - nmon_helper.sh code improvements
# 2017/07/30, Guilhem Marchand:
#                                       - Fully Qualified Domain Name improvements #46
# 2017/09/04, Guilhem Marchand:
#                                       - Fix unexpected operator issue when pid run time identification fails #47
# 2017/09/09, Guilhem Marchand:
#                                       - Missing external scripts generation for Solaris #49
# 2017/11/06, Guilhem Marchand:
#                                       - Solaris SARMON now compatible with SPARC processors

# Version 1.3.62

# For AIX / Linux / Solaris

#################################################
## 	Your Customizations Go Here            ##
#################################################

# hostname
HOST=`hostname`

# format date output to strftime dd/mm/YYYY HH:MM:SS
log_date () {
    date "+%d-%m-%Y %H:%M:%S"
}

if [ -z "${SPLUNK_HOME}" ]; then
	echo "`log_date`, ${HOST} ERROR, SPLUNK_HOME variable is not defined"
	exit 1
fi

# Splunk Home variable: This should automatically defined when this script is being launched by Splunk
# If you intend to run this script out of Splunk, please set your custom value here
SPL_HOME=${SPLUNK_HOME}

# Check SPL_HOME variable is defined, this should be the case when launched by Splunk scheduler
if [ -z "${SPL_HOME}" ]; then
	echo "`log_date`, ${HOST} ERROR, SPL_HOME (SPLUNK_HOME) variable is not defined"
	exit 1
fi

# APP path discovery
if [ -d "$SPLUNK_HOME/etc/apps/TA-nmon" ]; then
        APP=$SPLUNK_HOME/etc/apps/TA-nmon

elif [ -d "$SPLUNK_HOME/etc/slave-apps/TA-nmon" ];then
        APP=$SPLUNK_HOME/etc/slave-apps/TA-nmon

else
        echo "`log_date`, ${HOST} ERROR, the APP directory could not be defined, is the TA-nmon installed ?"
        exit 1
fi

# Var directory for data generation
APP_VAR=$SPLUNK_HOME/var/log/nmon

# Create directory if not existing already
[ ! -d $APP_VAR ] && { mkdir -p $APP_VAR; }

# Which type of OS are we running
UNAME=`uname`

# Linux binaries are stored in the bin/linux.tgz archive file
# At first startup only, if the linux directory does not exist, extract the binaries archive file
case $UNAME in

Linux )

if [ ! -d ${APP}/bin/linux ]; then
    cd ${APP}/bin
    tar -xzpf linux.tgz
fi

;;
esac

# Silently update bin content to run directory (see after this)
# Note: on some systems, cp is an alias to cp -i which would prevent this from working as expected
update_var_bin () {
cd ${APP}/bin
case $UNAME in
    Linux )
    tar -xzpf linux.tgz ;;
esac
\cp -pf ${APP}/default/app.conf ${APP_VAR}/app.conf > /dev/null 2>&1
\cp -rpf ${APP}/bin ${APP_VAR}/ > /dev/null 2>&1
}

# To prevents binaries overwrites during upgrades and sh cluster deployment issues, cache the bin directory
# Binaries will be launched from the cache directory
if [ -d ${APP_VAR}/bin ]; then

    # the bin directory has been already cached, verify if an update is required
    if [ -f ${APP_VAR}/app.conf ]; then

        diff ${APP}/default/app.conf ${APP_VAR}/app.conf >/dev/null

            # if return code does not equal to 0, update is required
            if [ $? -ne 0 ]; then
                update_var_bin
            fi

    else

        # no app.conf found, force copy of app.conf and update
        update_var_bin
    fi

else

    # the bin directory has not been cached already
    update_var_bin

fi

# Fix nmon.conf format issue when pushed by the SHC deployer on search heads
reformat_default_nmon_conf () {
    sed -i 's/ = /=/g' ${APP}/default/nmon.conf
    sed -i 's/\[default\]//g' ${APP}/default/nmon.conf
}


###
### Legacy options for nmon writing to regular files (these values are used by the TA-nmon not using fifo files)
###

# set defaults values for interval and snapshot and source nmon.conf

### All these values are defaults values, and will be overcharged by default/nmon.conf and local/nmon.conf if they exists ###

# Refresh interval in seconds, Nmon will this value to refresh data each X seconds
# Default to 60 seconds
interval="60"
	
# Number of Data refresh snapshots, Nmon will refresh data X times
# Default to 120 snapshots
snapshot="120"

###
### FIFO options: used since release 1.3.0
###

# Using FIFO files (named pipe) are now used to minimize the CPU footprint of the technical addons
# As such, it is not required anymore to use short cycle of Nmon run to reduce the CPU usage

# You can still want to manage the volume of data to be generated by managing the interval and snapshot values
# as a best practice recommendation, the time to live of nmon processes writing to FIFO should be 24 hours

# value for interval: time in seconds between 2 performance measures
fifo_interval="60"

# value for snapshot: number of measure to perform
fifo_snapshot="1440"

# AIX common options default, will be overwritten by nmon.conf (unless the file would not be available)

# Note: Since the version 1.3.0, AIX uses fifo files to minimize the CPU footprint, this requires the -F option
# and is not compatible with the "-f" option that defines output to csv
# The -F option is implicitly added by the nmon_helper.sh script during processing

AIX_options="-T -A -d -K -L -M -P -O -W -S -^ -p"

# Linux max devices (-d option), default to 1500
Linux_devices="1500"

# Change the priority applied while looking at nmon binary
# by default, the nmon_helper.sh script will use any nmon binary found in PATH
# Set to "1" to give the priority to embedded nmon binaries
Linux_embedded_nmon_priority="0"

# Change the limit for processes and disks capture of nmon for Linux
# In default configuration, nmon will capture most of the process table by capturing main consuming processes
# You can set nmon to an unlimited number of processes to be captured, and the entire process table will be captured.
# Note this will affect the number of disk devices captured by setting it to an unlimited number.
# This will also increase the volume of data to be generated and may require more cpu overhead to process nmon data
# The default configuration uses the default mode (limited capture), you can set bellow the limit number of capture to unlimited mode
# Change to "1" to set capture of processes and disks to no limit mode
Linux_unlimited_capture="0"

# endtime_margin defines the time in seconds before a new nmon process will be started
# in default configuration, a new process will be spawned 240 seconds before the current process ends
# see nmon.conf (this value will be overwritten by nmon.conf)
endtime_margin="240"

# Linux disks extended statistics (see nmon.conf)
Linux_disk_dg_enable="1"

# Name of the DG group file
Linux_disk_dg_group="auto"

# nmon external generation, default is activated
nmon_external_generation="1"

# nmon fifo mode, default is activated
mode_fifo="1"

# source default nmon.conf

# Notes: in a search head running in SHC, the creation of a local/nmon.conf will make the SHC deployer
# reformatting the conf file in a Splunk fashion
# this is however not compatible with a shell sourcing of the file
# If we detect this case, the nmon.conf file will be reformatted to match our constraints

if [ -f $APP/default/nmon.conf ]; then

    case $UNAME in
    Linux)
        # If this pattern is found, then the file needs to be corrected because it has been changed by the SHC deployer
        grep '\[default\]' $APP/default/nmon.conf >/dev/null
        if [ $? -eq 0 ]; then
            reformat_default_nmon_conf
            . $APP/default/nmon.conf
        else
            . $APP/default/nmon.conf
        fi
        ;;
    *)
        . $APP/default/nmon.conf
        ;;
    esac

fi

# source local nmon.conf, if any

# Search for a local nmon.conf file located in $SPLUNK_HOME/etc/apps/TA-nmon/local
if [ -f $APP/local/nmon.conf ]; then
	. $APP/local/nmon.conf
fi

# On a per server basis, you can also set in /etc/nmon.conf
if [ -f /etc/nmon.conf ]; then
	. /etc/nmon.conf
fi

# Manage FQDN option
echo $nmon2csv_options | grep '\-\-use_fqdn' >/dev/null
if [ $? -eq 0 ]; then
    HOST=`hostname -f`
else
    HOST=`hostname`
fi

# Nmon Binary
case $UNAME in

##########
#	AIX	#
##########

AIX )

# Use topas_nmon in priority

if [ -x /usr/bin/topas_nmon ]; then
	NMON="/usr/bin/topas_nmon"
	AIX_topas_nmon="true"

else
	NMON=`which nmon 2>&1`

	if [ ! -x "$NMON" ]; then
		echo "`log_date`, ${HOST} ERROR, Nmon could not be found, cannot continue."
		exit 1
	fi
	AIX_topas_nmon="false"	

fi

;;

##########
#	Linux	#
##########

# Nmon App comes with most of nmon versions available from http://nmon.sourceforge.net/pmwiki.php?n=Site.Download

Linux )

case $Linux_embedded_nmon_priority in

0)

	# give priority to any nmon binary found in local PATH

	# Nmon BIN full path (including bin name), please update this value to reflect your Nmon installation
	which nmon >/dev/null 2>&1

	if [ $? -eq 0 ]; then

		NMON=`which nmon`

	else

		NMON=""

	fi

;;

1)

	# give priority to embedded binaries
	# if none of embedded binaries can suit the local system, we will switch to local nmon binary, if it's available

	NMON=""

;;

esac

if [ ! -x "$NMON" ];then

	# No nmon found in env, so using prepackaged version

	# First, define the processor architecture, use the arch command in priority, fall back to uname -m if not available
	which arch >/dev/null 2>&1
	if [ $? -eq 0 ]; then

			ARCH=`arch`
			
	else
	
			ARCH=`uname -m`	
	
	fi
	
	# Let's convert some of architecture names to more conventional names, specially used by the nmon community to name binaries (not that ppc32 is more or less clear than power_32...)

	case $ARCH in
	
	i686 )
	
		ARCH_NAME="x86" ;; # x86 32 bits
		
	x86_64 )
	
		ARCH_NAME="x86_64" ;; # x86 64 bits
		
	ia64 )
	
		ARCH_NAME="ia64" ;; # Itanium 64 bits	
	
	ppc32* )
	
		ARCH_NAME="power_32" ;; # powerpc 32 bits
		
	ppc64* )
	
		ARCH_NAME="power_64" ;; # powerpc 64 bits	

	s390 )
	
		ARCH_NAME="mainframe_32" ;; # s390 32 bits mainframe	

	s390x )
	
		ARCH_NAME="mainframe_64" ;; # s390x 64 bits mainframe

    arm* )

        ARCH_NAME="arm" ;; # arm architecture

    * )

        ARCH_NAME="${ARCH}" ;; # None of those!
	
	esac

	### PowerLinux specific ###

	# On PowerLinux arch, some OS can run in Big Endian while most will run in Little Endian
    # On a Little Endian system, the following command will return "1" for a Little Endian arch

    # See this nice article: https://www.mainline.com/linux-on-power-to-be-or-not-to-be-why-should-i-care
    # And specifically "Ubuntu is LE only; SLES 11 is BE only; SLES 12 is LE only; RedHat 6.x is BE only; RedHat 7.1 has two distributions – one LE, the other BE"

    # For convenience, all powerLinux binaries are suffixed by "_le" or "_be"

    case $ARCH in

    ppc32* | ppc64* )

        # Assign default to Little Endian in case of failure
        BYTE_ORDER_STATUS="1"
        BYTE_ORDER="le"

        BYTE_ORDER_STATUS=`echo I | tr -d [:space:] | od -to2 | head -n1 | awk '{print $2}' | cut -c6`
        case ${BYTE_ORDER_STATUS} in

        0 )
        # Big Endian
            BYTE_ORDER="be" ;;

        # Little Endian
        1 )
            BYTE_ORDER="le" ;;

        esac

    ;;
    esac

	# Initialize linux_vendor
	linux_vendor=""
	linux_mainversion=""
	linux_subversion=""
	linux_fullversion=""
	
	# Try to find the better embedded binary depending on Linux version
	
	# Most modern Linux comes with an /etc/os-release, this is (from far) the better scenario for system identification
	
	OSRELEASE="/etc/os-release"	
	
	if [ -f $OSRELEASE ]; then

		# Great, let's try to find the better binary for that system
	
		linux_vendor=`grep '^ID=' $OSRELEASE | awk -F= '{print $2}' | sed 's/\"//g' | sed 's/ //g'`	# The Linux distribution
		linux_mainversion=`grep '^VERSION_ID=' $OSRELEASE | awk -F'"' '{print $2}' | awk -F'.' '{print $1}'`	# The main release (eg. rhel 7)

        # some distribution (eg. Fedora) seem to use a non standard format
        case $linux_mainversion in
        "")
            linux_mainversion=`grep '^VERSION_ID=' $OSRELEASE | sed 's/ //g' | sed 's/\"//' | awk -F'=' '{print $2}'` ;;
        esac

		linux_subversion=`grep '^VERSION_ID=' $OSRELEASE | awk -F'"' '{print $2}' | awk -F'.' '{print $2}'`	# The sub level release (eg. "1" from rhel 7.1)
		linux_fullversion=`grep '^VERSION_ID=' $OSRELEASE | awk -F'"' '{print $2}' | sed 's/\.//g'`	# Concatenated version of the release (eg. 71 for rhel 7.1)	

        case $ARCH in

        # PowerLinux
        ppc32* | ppc64* )

            # Manage Big / Little Endian arch
            case ${BYTE_ORDER} in

            # Big Endian
            "be" )

                # Try the most accurate
                if [ -f $APP_VAR/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_fullversion}_be ]; then
                    NMON="$APP_VAR/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_fullversion}_be"

                # try the mainversion
                elif [ -f ${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}_be ]; then
                    NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}_be"

                # try the linux_vendor
                elif [ -f ${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}_be ]; then
                    NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}_be"

                fi

            ;;

            # Little Endian
            "le" )

                # Try the most accurate
                if [ -f $APP_VAR/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_fullversion}_le ]; then
                    NMON="$APP_VAR/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_fullversion}_le"

                # try the mainversion
                elif [ -f ${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}_le ]; then
                    NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}_le"

                # try the linux_vendor
                elif [ -f ${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}_le ]; then
                    NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}_le"

                fi

            ;;

            esac

        ;;

        # All other arch
        *)

                # Try the most accurate
                if [ -f $APP_VAR/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_fullversion} ]; then
                    NMON="$APP_VAR/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_fullversion}"

                # try the mainversion
                elif [ -f ${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion} ]; then
                    NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}"

                # try the linux_vendor
                elif [ -f ${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor} ]; then
                    NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}"

                fi

        ;;

        esac


	# So bad, no os-release, probably old linux, things becomes a bit harder

	# centOS, OS and version detection
    elif [ -f /etc/centos-release ]; then

       for version in 5 6 7; do
           if grep "CentOS release $version" /etc/centos-release >/dev/null; then

               linux_vendor="centos"
               linux_mainversion="$version"
               NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}"

           fi

        done

    # rhel, OS and version detection
	elif [ -f /etc/redhat-release ]; then

        # Redhat has some version for PowerLinux that can be Little or Big endian

		for version in 4 5 6 7; do
	
			# search for rhel		
			if grep "Red Hat Enterprise Linux Server release $version" /etc/redhat-release >/dev/null; then
		
				linux_vendor="rhel"
				linux_mainversion="$version"

                case $ARCH in

                # PowerLinux
                ppc32* | ppc64* )

                    # Manage Big / Little Endian arch
                    case ${BYTE_ORDER} in

                    # Big endian
                    "be" )
                        NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}_be"

				    ;;

				    # Little endian
				    "le")
    				    NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}_le"
				    ;;

				    esac

				;;

				# Other arch
				* )
				    NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}"

                ;;

                esac

			fi
			
		done

	# Second chance for sles and opensuse, /etc/SuSE-release is deprecated and should be removed in future version
	elif [ -f /etc/SuSE-release ]; then
	
		# sles
		
		if grep "SUSE Linux Enterprise Server" /etc/SuSE-release >/dev/null; then
		
			linux_vendor="sles"
			# Get the main version only
			linux_mainversion=`grep 'VERSION =' /etc/SuSE-release | sed 's/ //g' | awk -F= '{print $2}' | awk -F. '{print $1}'`
            linux_subversion=`grep 'PATCHLEVEL =' /etc/SuSE-release | sed 's/ //g' | awk -F= '{print $2}' | awk -F. '{print $1}'`

            case $ARCH in

            # PowerLinux
            ppc32* | ppc64* )

                # Manage Big / Little Endian arch
                case ${BYTE_ORDER} in

                # Big endian
                "be" )
                    NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}_be"

                ;;

                # Little endian
                "le")
                    NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}_le"
                ;;

                esac

            ;;

            # Other arch
            * )
                NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}"

            ;;

            esac

		elif grep "openSUSE" /etc/SuSE-release >/dev/null; then
		
			linux_vendor="opensuse"
			# Get the main version only
			linux_mainversion=`grep 'VERSION =' /etc/SuSE-release | sed 's/ //g' | awk -F= '{print $2}' | awk -F. '{print $1}'`
            linux_subversion=`grep 'PATCHLEVEL =' /etc/SuSE-release | sed 's/ //g' | awk -F= '{print $2}' | awk -F. '{print $1}'`

            # try the most accurate
            if [ -f ${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}${linux_subversion} ]; then
                    NMON=" ${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}${linux_subversion}"
            else
                    NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}"
            fi

		fi
	
	elif [ -f /etc/issue ]; then

		# search for debian (note: starting debian 7, the /etc/os-release should be available)
		# This shall not be updated in the future as the /etc/os-release is now available by default

		if grep "Debian GNU/Linux" /etc/issue >/dev/null; then

			for version in 5 6 7; do
	
				if grep "Debian GNU/Linux $version" /etc/issue >/dev/null; then
		
					linux_vendor="debian"
					linux_mainversion="$version"
					NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}"

				fi
		
			done

        # Ubuntu is Little Endian only
		elif grep "Ubuntu" /etc/issue >/dev/null; then

			for version in 6 7 8 9 10 11 12 13 14 15; do
	
				if grep "Ubuntu $version" /etc/issue >/dev/null; then
		
					linux_vendor="ubuntu"
					linux_mainversion="$version"

                    case $ARCH in

                    # PowerLinux
                    ppc32* | ppc64* )

                        # Manage Big / Little Endian arch
                        case ${BYTE_ORDER} in

                        # Big endian
                        "be" )
                            NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}_be"

                        ;;

                        # Little endian
                        "le")
                            NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}_le"
                        ;;

                        esac

                    ;;

                    # Other arch
                    * )
                        NMON="${APP_VAR}/bin/linux/${linux_vendor}/nmon_${ARCH_NAME}_${linux_vendor}${linux_mainversion}"

                    ;;

                    esac

				fi
		
			done

		fi
		
	fi

	# Verify NMON is set and exists, if not, try falling back to generic builds

	case $NMON in
	
	"")
	
		# Look for local binary in PATH
		which nmon >/dev/null 2>&1
		
		if [ $? -eq 0 ]; then
			NMON=`which nmon 2>&1`
		else

            case $ARCH in

            # PowerLinux
            ppc32* | ppc64* )

                # Manage Big / Little Endian arch
                case ${BYTE_ORDER} in

                # Big endian
                "be" )
                    NMON="${APP_VAR}/bin/linux/generic/nmon_linux_${ARCH_NAME}_be"

                ;;

                # Little endian
                "le")
                    NMON="${APP_VAR}/bin/linux/generic/nmon_linux_${ARCH_NAME}_le"
                ;;

                esac

            ;;

            # Other arch
            * )
                NMON="${APP_VAR}/bin/linux/generic/nmon_linux_${ARCH_NAME}"

            ;;

            esac

		fi
    ;;

    *)
        if [ ! -x ${NMON} ]; then

            # Look for local binary in PATH
            which nmon >/dev/null 2>&1

            if [ $? -eq 0 ]; then
                    NMON=`which nmon 2>&1`
            fi

        fi

    ;;

	esac

	# Finally verify we have a binary that exists and is executable
	
	if [ ! -x ${NMON} ]; then

		if [ -x ${APP_VAR}/bin/linux/generic/nmon_linux_${ARCH} ]; then
		
			# Try switching to embedded generic

            case $ARCH in

            # PowerLinux
            ppc32* | ppc64* )

                # Manage Big / Little Endian arch
                case ${BYTE_ORDER} in

                # Big endian
                "be" )
                    NMON="${APP_VAR}/bin/linux/generic/nmon_linux_${ARCH_NAME}_be"

                ;;

                # Little endian
                "le")
                    NMON="${APP_VAR}/bin/linux/generic/nmon_linux_${ARCH_NAME}_le"
                ;;

                esac

            ;;

            # Other arch
            * )
                NMON="${APP_VAR}/bin/linux/generic/nmon_linux_${ARCH_NAME}"

            ;;

            esac

		else
			
			echo "`log_date`, ${HOST} ERROR, could not find an nmon binary suitable for this system, please install nmon manually and set it available in the user PATH"
			exit 1
			
		fi	
	
	fi

fi

;;

##########
#	SunOS	#
##########

SunOS )

# Nmon BIN full path (including bin name), please update this value to reflect your Nmon installation
NMON=`which sadc 2>&1`
if [ ! -x "$NMON" ];then

	# No nmon found in env, so using prepackaged version
	sun_arch=`uname -a`
	
	echo ${sun_arch} | grep sparc >/dev/null
	case $? in
	0 )
		NMON="$APP_VAR/bin/sarmon_bin_sparc/sadc" ;;
	* )
		# arch is x86
		NMON="$APP_VAR/bin/sarmon_bin_i386/sadc" ;;
	esac

fi

;;

* )

	echo "`log_date`, ${HOST} ERROR, Unsupported system ! Nmon is available only for AIX / Linux / Solaris systems, please check and deactivate nmon data collect"
	exit 2

;;

esac

# Nmon file final destination
# Default to nmon_repository of Nmon Splunk App
NMON_REPOSITORY=${APP_VAR}/var/nmon_repository
[ ! -d $NMON_REPOSITORY ] && { mkdir -p $NMON_REPOSITORY; }

#also needed - 
[ -d ${APP_VAR}/var/csv_repository ] || { mkdir -p ${APP_VAR}/var/csv_repository; }
[ -d ${APP_VAR}/var/config_repository ] || { mkdir -p ${APP_VAR}/var/config_repository; }

# Nmon PID file
PIDFILE=${APP_VAR}/nmon.pid

# FIFO file 1
FIFO1_DIR=${NMON_REPOSITORY}/fifo1
FIFO1=${FIFO1_DIR}/nmon.fifo

# FIFO file 2
FIFO2_DIR=${NMON_REPOSITORY}/fifo2
FIFO2=${FIFO2_DIR}/nmon.fifo

# create dir
[ -d ${FIFO1_DIR} ] || { mkdir -p ${FIFO1_DIR}; }
[ -d ${FIFO2_DIR} ] || { mkdir -p ${FIFO2_DIR}; }

# ensure fifo files do not exist currently as regular files instead of named pipe
if [ -s $FIFO1 ]; then
    rm -f $FIFO1
fi

if [ -s $FIFO2 ]; then
    rm -f $FIFO2
fi

# create fifo files if required
if [ ! -p $FIFO1 ]; then
    mkfifo $FIFO1
fi

if [ ! -p $FIFO2 ]; then
    mkfifo $FIFO2
fi

# csv_repository
[ -d ${APP_VAR}/var/csv_repository ] || { mkdir -p ${APP_VAR}/var/csv_repository; }

#
# Interpreter choice
#

PYTHON=0
PERL=0
# Set the default interpreter
INTERPRETER="python"

# Get the version for both worlds
PYTHON=`which python >/dev/null 2>&1`
PERL=`which python >/dev/null 2>&1`

case $PYTHON in
*)
   python_subversion=`python --version 2>&1`
   case $python_subversion in
   *" 2.7"*)
    PYTHON_available="true" ;;
   *)
    PYTHON_available="false"
   esac
   ;;
0)
   PYTHON_available="false"
   ;;
esac

case $PERL in
*)
   PERL_available="true"
   ;;
0)
   PERL_available="false"
   ;;
esac

case `uname` in

# AIX priority is Perl
"AIX")
     case $PERL_available in
     "true")
           INTERPRETER="perl" ;;
     "false")
           INTERPRETER="python" ;;
 esac
;;

# Other OS, priority is Python
*)
     case $PYTHON_available in
     "true")
           INTERPRETER="python" ;;
     "false")
           INTERPRETER="perl" ;;
     esac
;;
esac

############################################
# functions
############################################

# create snap scripts for nmon_external

create_nmon_external () {

# fifo_started variable is exported by the function start_fifo_reader
case $fifo_started in
"fifo1")
    cat ${APP}/bin/nmon_external_cmd/nmon_external_start.sh | sed "s|NMON_FIFO_PATH|$NMON_EXTERNAL_DIR|g" > "${APP_VAR}/bin/nmon_external_cmd/nmon_external_start_fifo1.sh"
    chmod +x "${APP_VAR}/bin/nmon_external_cmd/nmon_external_start_fifo1.sh"
    cat ${APP}/bin/nmon_external_cmd/nmon_external_snap.sh | sed "s|NMON_FIFO_PATH|$NMON_EXTERNAL_DIR|g" > "${APP_VAR}/bin/nmon_external_cmd/nmon_external_snap_fifo1.sh"
    chmod +x "${APP_VAR}/bin/nmon_external_cmd/nmon_external_snap_fifo1.sh"
    ;;
"fifo2")
    cat ${APP}/bin/nmon_external_cmd/nmon_external_start.sh | sed "s|NMON_FIFO_PATH|$NMON_EXTERNAL_DIR|g" > "${APP_VAR}/bin/nmon_external_cmd/nmon_external_start_fifo2.sh"
    chmod +x "${APP_VAR}/bin/nmon_external_cmd/nmon_external_start_fifo2.sh"
    cat ${APP}/bin/nmon_external_cmd/nmon_external_snap.sh | sed "s|NMON_FIFO_PATH|$NMON_EXTERNAL_DIR|g" > "${APP_VAR}/bin/nmon_external_cmd/nmon_external_snap_fifo2.sh"
    chmod +x "${APP_VAR}/bin/nmon_external_cmd/nmon_external_snap_fifo2.sh"
    ;;
esac

}

# Verify that we don't spawn multiple instances of nmon external snap script
# this issue is unexpected and has been reported on some cases in AIX
# If this occurs, don't let processes multiplication happening

# Any process running more than 2 minutes will be killed

check_duplicated_external_snap () {

        # get the list of occurrences
        count="0"
        count=`ps -ef | grep nmon_external_snap | grep -v grep | wc -l`

        if [ $count -gt 0 ]; then
                oldPidList=`ps -ef | grep nmon_external_snap | grep -v grep | awk '{print $2}'`
                for pid in $oldPidList; do
                    pid_runtime=0
                    # only run the process is running
                    if [ -d /proc/${pid} ]; then
                        # get the process runtime in seconds
                        pid_runtime=`ps -p ${pid} -oetime= | tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`

                        case ${pid_runtime} in

                            ''|*[!0-9]*)
                                echo "`log_date`, ${HOST} WARN: run time identification of processwith pid ${pid} failed, it has been probably terminated"
                                ;;
                            *)

                                if [ ${pid_runtime} -gt 120 ]; then
                                    echo "`log_date`, ${HOST} WARN: fifo nmon external snap script took long and will be killed (SIGTERM): `ps -p ${pid} -ouser,pid,command,etime,args | grep -v PID`"
                                    kill $pid

                                    # Allow some time for the process to end
                                    sleep 1

                                    # re-check the status
                                    ps -p ${pid} -oetime= >/dev/null

                                    if [ $? -eq 0 ]; then
                                    echo "`log_date`, ${HOST} WARN, fifo nmon external snap due to `ps -eo user,pid,command,etime,args | grep $pid | grep -v grep` failed to stop, killing (-9) process $pid"
                                        kill -9 $pid
                                    fi

                                fi
                                ;;

                        esac

                    fi
                done
        fi

}

# For AIX / Linux, the -p option when launching nmon will output the instance pid in stdout

start_nmon () {

#
# Set Nmon command line
#

# NOTE:

# Collecting NFS Statistics:

# --> Since Nmon App Version 1.5.0, NFS activation can be controlled by the nmon.conf file in default/local directories

# - Linux: Add the "-N" option if you want to extract NFS Statistics (NFS V2/V3/V4)
# - AIX: Add the "-N" option for NFS V2/V3, "-NN" for NFS V4

# For AIX, the default command options line "-f -T -A -d -K -L -M -P -O -W -S -^" includes: (see http://www-01.ibm.com/support/knowledgecenter/ssw_aix_61/com.ibm.aix.cmds4/nmon.htm)

# AIX options can be managed using local/nmon.conf, do not modify options here

# -A	Includes the Asynchronous I/O section in the view.
# -d	Includes the Disk Service Time section in the view.
# -K	Includes the RAW Kernel section and the LPAR section in the recording file. The -K flag dumps the raw numbers
# of the corresponding data structure. The memory dump is readable and can be used when the command is recording the data.
# -L	Includes the large page analysis section.
# -M	Includes the MEMPAGES section in the recording file. The MEMPAGES section displays detailed memory statistics per page size.
# -O    Includes the Shared Ethernet adapter (SEA) VIOS sections in the recording file.
# -W    Includes the WLM sections into the recording file.
# -S	Includes WLM sections with subclasses in the recording file.
# -P	Includes the Paging Space section in the recording file.
# -T	Includes the top processes in the output and saves the command-line arguments into the UARG section. You cannot specify the -t, -T, or -Y flags with each other.
# -^	Includes the Fiber Channel (FC) sections.
# -p  print pid in stdout

# For Linux, the default command options line "-f -T -d 1500" includes:

# -t	include top processes in the output
# -T	as -t plus saves command line arguments in UARG section
# -d <disks>    to increase the number of disks [default 256]
# -p  print pid in stdout

case $UNAME in

AIX )

	# -p option is mandatory to get the pid of the launched instances, ensure it has been set

	echo ${AIX_options} | grep '\-p' >/dev/null
	if [ $? -ne 0 ]; then
		AIX_options="${AIX_options} -p"
	fi

	# Since release 1.3.0, we use fifo files, -f option is prohibited
    echo ${AIX_options} | grep '\-f' >/dev/null
    if [ $? -eq 0 ]; then
            AIX_options=`echo ${AIX_options} | sed 's/\-f //g'`
    fi

    # Set interval and snapshot for AIX
    case ${mode_fifo} in
    1)
        aix_interval=${fifo_interval}
        aix_snapshot=${fifo_snapshot}
    ;;
    *)
        aix_interval=${interval}
        aix_snapshot=${snapshot}
    ;;
    esac

    # option -y is compatible and mandatory, ensure it has been set
    echo ${AIX_options} | grep 'yoverwrite' >/dev/null
    if [ $? -ne 0 ]; then
            echo "`log_date`, ${HOST}, WARN, the -yoverwrite=1 option was not used while loading local settings (please review nmon.conf), option is mandatory and will be forced"
            AIX_options="${AIX_options} -yoverwrite=1"
    fi

    # Manage NFS
    if [ ${AIX_NFS23} -eq 1 ]; then
        nmon_command="-N -s ${aix_interval} -c ${aix_snapshot}"
    elif [ ${AIX_NFS4} -eq 1 ]; then
        nmon_command="-NN -s ${aix_interval} -c ${aix_snapshot}"
    else
        nmon_command="-s ${aix_interval} -c ${aix_snapshot}"
    fi

    # Set the nmon command for AIX
    case ${mode_fifo} in
    1)
        nmon_command_fifo1="${NMON} -F ${FIFO1} ${AIX_options} ${nmon_command}"
        nmon_command_fifo2="${NMON} -F ${FIFO2} ${AIX_options} ${nmon_command}"
        ;;
    *)

        nmon_command="${NMON} -f ${AIX_options} ${nmon_command}"
        ;;
    esac

;;

SunOS )

	nmon_command="${NMON} ${interval} ${snapshot}"
;;

Linux )

    # Since 1.2.47, Linux_unlimited_capture feature has changed
    # For historical reason, and in case the old activation value (1) has been set in local/nmon.conf, manage it.
    case ${Linux_unlimited_capture} in
    "1")
        Linux_unlimited_capture="-1" ;;
    esac

    # Set the default Linux minimal args list
    case ${mode_fifo} in
    1)
        Linux_nmon_args="-T -s ${fifo_interval} -c ${fifo_snapshot} -d ${Linux_devices}" ;;
    *)
        Linux_nmon_args="-T -s ${interval} -c ${snapshot} -d ${Linux_devices}" ;;
    esac

    case ${Linux_NFS} in
    "1" )
        Linux_nmon_args="$Linux_nmon_args -N" ;;
    esac

    case ${Linux_unlimited_capture} in
    "0" )
        Linux_nmon_args="$Linux_nmon_args" ;;
    "-1" )
        Linux_nmon_args="$Linux_nmon_args -I ${Linux_unlimited_capture}" ;;
    * )
        if [ `echo "${Linux_unlimited_capture}" | grep -E "^[0-9]+(\.[0-9]+)?$"` ]; then
            Linux_nmon_args="$Linux_nmon_args -I ${Linux_unlimited_capture}"
        else
            echo "`log_date`, ${HOST} ERROR, invalid value for Linux_unlimited_capture (${Linux_unlimited_capture} is not an integer or a floating number)"
            exit 2
        fi
        ;;
    esac

    case ${Linux_disk_dg_enable} in
    "1" )
        Linux_nmon_args="$Linux_nmon_args -g auto -D" ;;
    esac

    # Set the nmon command for Linux
    case ${mode_fifo} in
    "1")
        nmon_command_fifo1="${NMON} -F ${FIFO1} $Linux_nmon_args -p"
        nmon_command_fifo2="${NMON} -F ${FIFO2} $Linux_nmon_args -p"
        ;;
    *)
        nmon_command="${NMON} -f $Linux_nmon_args -p"
        ;;
    esac

;;

esac

#
# Starting Nmon
#

case $UNAME in

	AIX )

        # on AIX, prevent error messages linked to /usr/opt/freeware/bin/rpm
        unset LIBPATH

        case ${mode_fifo} in

        "1")

            # global nmon_external
            NMON_EXTERNAL_DIR="${APP_VAR}/var/nmon_repository/${fifo_started}"
            export NMON_EXTERNAL_DIR
            NMON_EXTERNAL_FIFO="${APP_VAR}/var/nmon_repository/${fifo_started}/nmon.fifo"
            export NMON_EXTERNAL_FIFO
            TIMESTAMP=0
            export TIMESTAMP
            NMON_ONE_IN=1
            export NMON_ONE_IN
            unset NMON_END

            # fifo_started variable is exported by the function start_fifo_reader
            case $fifo_started in
            "fifo1")
                case $nmon_external_generation in
                1)
                    # nmon_external
                    create_nmon_external
                    NMON_START="${APP_VAR}/bin/nmon_external_cmd/nmon_external_start_fifo1.sh"
                    export NMON_START
                    NMON_SNAP="${APP_VAR}/bin/nmon_external_cmd/nmon_external_snap_fifo1.sh"
                    export NMON_SNAP
                ;;
                esac

                echo "`log_date`, ${HOST} INFO: starting nmon : ${nmon_command_fifo1} in ${NMON_EXTERNAL_DIR}"
                ${nmon_command_fifo1} 2>&1 > ${APP_VAR}/nmon_output.txt

                if [ $? -ne 0 ]; then
                    echo "`log_date`, ${HOST} ERROR, nmon binary returned a non 0 code while trying to start, please verify error traces in splunkd log"
                fi

                # old topas-nmon version might not be compatible with the -y option, let's manage this
                cat ${APP_VAR}/nmon_output.txt | grep -i 'invalid option[^y]*y' >/dev/null
                if [ $? -eq 0 ]; then
                    # option -y is not compatible and not mandatory
                    echo "`log_date`, ${HOST}, ERROR, This system is running a topas-nmon version that does not support the -y option, you might need to consider an AIX upgrade: `cat ${APP_VAR}/nmon_output.txt`"
                    nmon_command_fifo1=`echo ${nmon_command_fifo1} | sed 's/\-yoverwrite=1//g'`
                    ${nmon_command_fifo1} 2>&1 > ${APP_VAR}/nmon_output.txt
                fi

                # Store the PID file (very last line of nmon output)
                if [ -f ${APP_VAR}/nmon_output.txt ]; then
                    tail -1 ${APP_VAR}/nmon_output.txt > ${PIDFILE}
                fi

            ;;

            "fifo2")
                case $nmon_external_generation in
                1)
                    # nmon_external
                    create_nmon_external
                    NMON_START="${APP_VAR}/bin/nmon_external_cmd/nmon_external_start_fifo2.sh"
                    export NMON_START
                    NMON_SNAP="${APP_VAR}/bin/nmon_external_cmd/nmon_external_snap_fifo2.sh"
                    export NMON_SNAP
                ;;
                esac

                echo "`log_date`, ${HOST} INFO: starting nmon : ${nmon_command_fifo2} in ${NMON_EXTERNAL_DIR}"
                ${nmon_command_fifo2} 2>&1 > ${APP_VAR}/nmon_output.txt

                if [ $? -ne 0 ]; then
                    echo "`log_date`, ${HOST} ERROR, nmon binary returned a non 0 code while trying to start, please verify error traces in splunkd log"
                fi

                # old topas-nmon version might not be compatible with the -y option, let's manage this
                cat ${APP_VAR}/nmon_output.txt | grep -i 'invalid option[^y]*y' >/dev/null
                if [ $? -eq 0 ]; then
                    # option -y is not compatible and not mandatory
                    echo "`log_date`, ${HOST}, ERROR, This system is running a topas-nmon version that does not support the -y option, you might need to consider an AIX upgrade: `cat ${APP_VAR}/nmon_output.txt`"
                    nmon_command_fifo2=`echo ${nmon_command_fifo2} | sed 's/\-yoverwrite=1//g'`
                    ${nmon_command_fifo2} 2>&1 > ${APP_VAR}/nmon_output.txt
                fi

                # Store the PID file (very last line of nmon output)
                if [ -f ${APP_VAR}/nmon_output.txt ]; then
                    tail -1 ${APP_VAR}/nmon_output.txt > ${PIDFILE}
                fi

            ;;

            esac

        ;;

        *)
            ${nmon_command} > ${PIDFILE}

        ;;

        esac

	;;

	Linux )

        case ${mode_fifo} in

        "1")

            # global nmon_external
            NMON_EXTERNAL_DIR="${APP_VAR}/var/nmon_repository/${fifo_started}"
            export NMON_EXTERNAL_DIR
            NMON_EXTERNAL_FIFO="${APP_VAR}/var/nmon_repository/${fifo_started}/nmon.fifo"
            export NMON_EXTERNAL_FIFO
            TIMESTAMP=0
            export TIMESTAMP
            NMON_ONE_IN=1
            export NMON_ONE_IN
            unset NMON_END

            # fifo_started variable is exported by the function start_fifo_reader
            case $fifo_started in
            "fifo1")
                case $nmon_external_generation in
                1)
                    # nmon_external
                    create_nmon_external
                    NMON_START="${APP_VAR}/bin/nmon_external_cmd/nmon_external_start_fifo1.sh"
                    export NMON_START
                    NMON_SNAP="${APP_VAR}/bin/nmon_external_cmd/nmon_external_snap_fifo1.sh"
                    export NMON_SNAP
                ;;
                esac
                nmon_command=${nmon_command_fifo1} ;;
            "fifo2")
                case $nmon_external_generation in
                1)
                    # nmon_external
                    create_nmon_external
                    NMON_START="${APP_VAR}/bin/nmon_external_cmd/nmon_external_start_fifo2.sh"
                    export NMON_START
                    NMON_SNAP="${APP_VAR}/bin/nmon_external_cmd/nmon_external_snap_fifo2.sh"
                    export NMON_SNAP
                ;;
                esac
                nmon_command=${nmon_command_fifo2} ;;
            esac

        ;;
        esac

	    # Retrieve the nmon Linux version
	    # Nmon 16x or superior is required to run disk group statistics

        NMON_VERSION=`$NMON -h | sed -n 's/.*[v|V]ersion[^0-9]*\([0-9][0-9]*\).*$/\1/p' | head -1`

        # Assume we can fail
        case $NMON_VERSION in
        "")
            # Set a default to 14 in case of identification failure
            NMON_VERSION="14" ;;
        esac

        if [ $NMON_VERSION -ge "16" ]; then

            # Activation of Linux disks extended stats generate a message in stdout
            # We don't want this as we need to retrieve the pid from nmon output
            # However, we also want to analyse the return code, so we can't filter out in only one operation

            echo "`log_date`, ${HOST} INFO: starting nmon : ${nmon_command} in ${NMON_EXTERNAL_DIR}"
            ${nmon_command} > ${APP_VAR}/nmon_output.txt

            if [ $? -ne 0 ]; then
                echo "`log_date`, ${HOST} ERROR, nmon binary returned a non 0 code while trying to start, please verify error traces in splunkd log (missing shared libraries?)"
            fi

            # Store the PID file (very last line of nmon output)
            if [ -f ${APP_VAR}/nmon_output.txt ]; then
                awk 'END{print}' ${APP_VAR}/nmon_output.txt > ${PIDFILE}
            fi

            # old nmon versions might not be compatible with disks extended stats, or the group file does not exist
            # In such a case, echo a WARN, remove the option and last chance start
            if grep 'opening disk group file' ${APP_VAR}/nmon_output.txt >/dev/null; then

                echo "`log_date`, ${HOST} WARN, nmon disks extended statistics cannot be collected, either this nmon version is not compatible or the disk group file does not exist, see ${APP_VAR}/nmon_output.txt"

                nmon_command=`echo ${nmon_command} | sed "s/-g ${Linux_disk_dg_group} -D//g"`
                echo "`log_date`, ${HOST} INFO: starting nmon : ${nmon_command} in ${NMON_EXTERNAL_DIR}"
                ${nmon_command} &> ${PIDFILE}

                if [ $? -ne 0 ]; then
                    echo "`log_date`, ${HOST} ERROR, nmon binary returned a non 0 code while trying to start, please verify error traces in splunkd log (missing shared libraries?)"
                fi

            fi

        else

            # This version is not compatible with the auto group disk
            nmon_command=`echo ${nmon_command} | sed "s/-g ${Linux_disk_dg_group} -D//g"`
            echo "`log_date`, ${HOST} INFO: starting nmon : ${nmon_command} in ${NMON_EXTERNAL_DIR}"
            ${nmon_command} > ${PIDFILE}

            if [ $? -ne 0 ]; then
                echo "`log_date`, ${HOST} ERROR, nmon binary returned a non 0 code while trying to start, please verify error traces in splunkd log (missing shared libraries?)"
            fi

        fi

	;;

	SunOS )

        case ${mode_fifo} in

        "1")

            # global nmon_external
            NMON_EXTERNAL_DIR="${APP_VAR}/var/nmon_repository/${fifo_started}"
            export NMON_EXTERNAL_DIR
            NMON_EXTERNAL_FIFO="${APP_VAR}/var/nmon_repository/${fifo_started}/nmon.fifo"
            export NMON_EXTERNAL_FIFO
            TIMESTAMP=0
            export TIMESTAMP
            NMON_ONE_IN=1
            export NMON_ONE_IN
            unset NMON_END

            # fifo_started variable is exported by the function start_fifo_reader
            case $fifo_started in
            "fifo1")
                case $nmon_external_generation in
                1)
                    # nmon_external
                    create_nmon_external
                    NMON_START="${APP_VAR}/bin/nmon_external_cmd/nmon_external_start_fifo1.sh"
                    export NMON_START
                    NMON_SNAP="${APP_VAR}/bin/nmon_external_cmd/nmon_external_snap_fifo1.sh"
                    export NMON_SNAP
                ;;
                esac
                NMONOUTPUTFILE="${APP_VAR}/var/nmon_repository/${fifo_started}/nmon.fifo"
                export NMONOUTPUTFILE
                ;;
            "fifo2")
                case $nmon_external_generation in
                1)
                    # nmon_external
                    create_nmon_external
                    NMON_START="${APP_VAR}/bin/nmon_external_cmd/nmon_external_start_fifo2.sh"
                    export NMON_START
                    NMON_SNAP="${APP_VAR}/bin/nmon_external_cmd/nmon_external_snap_fifo2.sh"
                    export NMON_SNAP
                ;;
                esac
                NMONOUTPUTFILE="${APP_VAR}/var/nmon_repository/${fifo_started}/nmon.fifo"
                export NMONOUTPUTFILE
                ;;
            esac

        ;;
        esac

		NMONNOSAFILE=1 # Do not generate useless sa files
		export NMONNOSAFILE

		# Manage UARG activation, default is on (1)
		NMONUARG_VALUE=${Solaris_UARG}
		if [ ! -z ${NMONUARG_VALUE} ]; then

			if [ ${NMONUARG_VALUE} -eq 1 ]; then
			NMONUARG=1
			export NMONUARG
			fi

		fi

		# Manage VxVM volume statistics activation, default is off (0)
		NMONVXVM_VALUE=${Solaris_VxVM}
		if [ ! -z ${NMONVXVM_VALUE} ]; then
		
			if [ ${NMONVXVM_VALUE} -eq 1 ]; then
			NMONVXVM=1
			export NMONVXVM
			fi
			
		fi

        echo "`log_date`, ${HOST} INFO: starting nmon : ${nmon_command} in ${NMON_REPOSITORY}"
		${nmon_command} >/dev/null 2>&1 &
	;;

esac

}

verify_pid() {

	givenpid=$1	

	# Verify proc fs before checking PID
	if [ -d /proc/${givenpid} ]; then
	
		case $UNAME in
	
			AIX )
			
				ps -ef | grep ${NMON} | grep -v grep | grep -v nmon_helper.sh | grep $givenpid ;;
		
			Linux )

				ps -ef | grep ${NMON} | grep -v grep | grep -v nmon_helper.sh | grep $givenpid ;;
				
			SunOS )
			
				/usr/bin/pwdx $givenpid ;;
							
		esac
		
	else
	
		# Just return nothing		
		echo ""
		
	fi

}

# Search for running process and write PID file
write_pid() {

# Only SunOS will look for running processes to identify nmon instances
# AIX and Linux will save the pid at launch time

case $UNAME in 

	SunOS)

        # In main priority, use pgrep (no truncation trouble), pgrep should always be available
        # whether running on Solaris 10 or 11
        if [ -x /usr/bin/pgrep ]; then
            PIDs=`pgrep -f ${NMON}`
        # Second priority, use BSD ps command with the appropriated syntax (mainly for Solaris 10)
        elif [ -x /usr/ucb/ps ]; then
            PIDs=`/usr/ucb/ps auxww | grep ${NMON} | grep -v grep | grep -v nmon_helper.sh | awk '{print $2}'`
        # Last, use the ps command with BSD style syntax (no -) for Solaris 11 and later
        # Solaris 10 cannot use BSD syntax with native ps, hopefully previous options should have been found !
        else
            if grep 'Solaris 10' /etc/release >/dev/null; then
                PIDs=`/usr/ucb/ps -ef | grep sarmon | grep -v grep | grep -v nmon_helper.sh | awk '{print $2}'`
            else
                PIDs=`/usr/ucb/ps auxww | grep ${NMON} | grep -v grep | grep -v nmon_helper.sh | awk '{print $2}'`
            fi
        fi

		for p in ${PIDs}; do

			verify_pid $p | grep -v grep | grep ${APP_VAR} >/dev/null

			if [ $? -eq 0 ]; then
				echo ${PIDs} > ${PIDFILE}
			fi

		done
	;;		
		
	esac
			
}

# Just Search for running process
search_nmon_instances() {

case $UNAME in 

	Linux)

		PIDs=`ps -ef | grep ${NMON} | grep -v grep | grep -v nmon_helper.sh | awk '{print $2}'`
		
	;;
	
	SunOS)

		PIDs=`ps -ef | grep ${NMON} | grep -v grep | grep -v nmon_helper.sh | awk '{print $2}'`

		for p in ${PIDs}; do

			verify_pid $p | grep -v grep | grep ${APP_VAR} >/dev/null

		done
	;;		
		
	AIX)

		case ${AIX_topas_nmon} in
	
		true )	
			PIDs=`ps -ef | grep ${NMON} | grep -v grep | grep -v nmon_helper.sh | grep ${NMON_REPOSITORY} | awk '{print $2}'`
		;;
		
		false)
			PIDs=`ps -ef | grep ${NMON} | grep -v grep | grep -v nmon_helper.sh | awk '{print $2}'`
		;;
		
		esac

	;;
			
	esac
			
}

start_fifo_reader () {

case ${mode_fifo} in

"1")

    # Check fifo readers, start if either fifo1 or fifo2 is free
    fifo_started="none"

    # be portable
    running_fifo=`ps -ef | awk '/fifo_reader.py --fifo fifo1/ || /fifo_reader.py --fifo fifo2/ || /fifo_reader.pl --fifo fifo1/ || /fifo_reader.pl --fifo fifo2/' | grep -v awk`
    echo $running_fifo | grep 'fifo1' >/dev/null

    if [ $? -eq 0 ]; then
        echo "`log_date`, ${HOST} INFO: The fifo_reader fifo1 is running"
        echo $running_fifo | grep 'fifo2' >/dev/null
        if [ $? -eq 0 ]; then
            echo "`log_date`, ${HOST} INFO: The fifo_reader fifo2 is running"
        else
            echo "`log_date`, ${HOST} INFO: starting the fifo_reader fifo2"
            case $INTERPRETER in
            "perl")
                nohup $APP/bin/fifo_reader.pl --fifo fifo2 </dev/null >/dev/null 2>&1 & ;;
            "python")
                nohup $APP/bin/fifo_reader.py --fifo fifo2 </dev/null >/dev/null 2>&1 & ;;
            esac
            echo $! > ${APP_VAR}/var/fifo_reader_fifo2.pid
            fifo_started="fifo2"
            export fifo_started
        fi
    else
        echo "`log_date`, ${HOST} INFO: starting the fifo_reader fifo1"
        case $INTERPRETER in
        "perl")
            nohup $APP/bin/fifo_reader.pl --fifo fifo1 </dev/null >/dev/null 2>&1 & ;;
        "python")
            nohup $APP/bin/fifo_reader.py --fifo fifo1 </dev/null >/dev/null 2>&1 & ;;
        esac
        echo $! > ${APP_VAR}/var/fifo_reader_fifo1.pid
        fifo_started="fifo1"
        export fifo_started
    fi

;;
esac

}

############################################
# Defaults values for interval and snapshot
############################################

# Set interval and snapshot values depending on mode of collect

case $mode in

	shortperiod_low)
			interval="60"
			snapshot="10"
	;;
	
	shortperiod_middle)
			interval="30"
			snapshot="20"
	;;
	
	shortperiod_high)
			interval="20"
			snapshot="30"
	;;		

	longperiod_low)
			interval="240"
			snapshot="120"
	;;

	longperiod_middle)
			interval="120"
			snapshot="120"
	;;

	longperiod_high)
			interval="60"
			snapshot="120"
	;;

	custom)
			interval=${custom_interval}
			snapshot=${custom_snapshot}
	;;

esac	

####################################################################
#############		Main Program 			############
####################################################################

# Initialize PID variable
PIDs="" 

# Initialize nmon status
nmon_isstarted=0

# Check nmon binary exists and is executable
if [ ! -x ${NMON} ]; then
	
	echo "`log_date`, ${HOST} ERROR, could not find Nmon binary (${NMON}) or execution is unauthorized"
	exit 2
fi	

# cd to root dir
cd ${NMON_REPOSITORY}

# Check PID file, if no PID file is found, start nmon
if [ ! -f ${PIDFILE} ]; then

	# search for any App related instances
	search_nmon_instances

	case ${PIDs} in
	
	"")
        start_fifo_reader
        sleep 1
        start_nmon
		sleep 5 # Let nmon time to start
		write_pid
		exit 0
	;;
	
	*)

		echo "`log_date`, ${HOST} INFO: found Nmon running with PID ${PIDs}"
		# Retry to write pid file
		write_pid
		exit 0
	;;
	
	esac

else

	# PID file found

	SAVED_PID=`cat ${PIDFILE} | awk '{print $1}'`

	if [ ${endtime_margin} -gt 0 ]; then
	
		# Initialize PIDAGE to 01 Jan 2000 00:00:00 GMT for later failure verification
		EPOCHTEST="946684800"
		PIDAGE=$EPOCHTEST

        case ${INTERPRETER} in

        "perl")

            # Use Perl to get PID file age in seconds
            perl -e "\$mtime=(stat(\"$PIDFILE\"))[9]; \$cur_time=time();  print \$cur_time - \$mtime;" > ${APP_VAR}/nmon_helper.sh.tmp.$$
            ;;

        "python")

            # Use Python to get PID file age in seconds
            python -c "import os; import time; now = time.strftime(\"%s\"); print(int(int(now)-(os.path.getmtime('$PIDFILE'))))" > ${APP_VAR}/nmon_helper.sh.tmp.$$
            ;;

        esac

		PIDAGE=`cat ${APP_VAR}/nmon_helper.sh.tmp.$$`
		rm ${APP_VAR}/nmon_helper.sh.tmp.$$

        case $PIDAGE in
        "")
                echo "`log_date`, ${HOST} WARN: failed to eval the age of the current pid file, gaps may occur between nmon processes run."
                PIDAGE=0
                ;;
        esac

		# Estimate the end time of current Nmon binary less 4 minutes (enough time for new nmon process to start collecting)
		# Use expr for portability with sh

		# verify if we use fifo versus regular files
		case ${mode_fifo} in
		"1")
		    endtime=`expr ${fifo_interval} \* ${fifo_snapshot}` ;;
        *)
            endtime=`expr ${interval} \* ${snapshot}` ;;
        esac

		endtime=`expr ${endtime} - ${endtime_margin}`
	
	fi

	case ${SAVED_PID} in
	
	# PID file is empty
	"")

		echo "`log_date`, ${HOST} INFO: Removing stale pid file (empty file)"
		rm -f ${PIDFILE}

		# search for any App related instances
		search_nmon_instances

		case ${PIDs} in
	
		"")
            start_fifo_reader
            sleep 1
            start_nmon

            sleep 5 # Let nmon time to start
			# Relevant for Solaris Only
			write_pid
			exit 0
		;;
	
		*)

			echo "`log_date`, ${HOST} INFO: found Nmon running with PID ${PIDs}"
			# Relevant for Solaris Only
			write_pid
			exit 0
		;;
	
		esac

	;;

	# PID file is not empty
	*)
	
	case $UNAME in

	Linux)
		if [ -d /proc/${SAVED_PID} ]; then
			istarted="true"
		else
			istarted="false"
		fi
		;;

	SunOS)
		verify_pid ${SAVED_PID} | grep -v grep | grep ${NMON_REPOSITORY} >/dev/null
		if [ $? -eq 0 ]; then
			istarted="true"
		else
			istarted="false"
		fi
		;;
				
	AIX)
	
		if [ -d /proc/${SAVED_PID} ]; then
			istarted="true"
		else
			istarted="false"
		fi
		;;		
		
	esac	

	case $istarted in
	
	"true")

		if [ ${endtime_margin} -gt 0 ]; then

			# If the current age of the Nmon process requires starting a new one to prevent data gaps between collections
			# Note that the pidfile will be overwritten, for a few minutes 2 Nmon binaries are running in the same time
			# Data duplication will be managed by nmon2csv files	
		
			# Prevent any failure in determining nmon process age
			if [ $PIDAGE -gt $EPOCHTEST ]; then
				echo "`log_date`, ${HOST} ERROR: Failed to determine age in seconds of current Nmon process, gaps may occur between Nmon collections"
		
			else		
				case $PIDAGE in
			
				"")
					echo "`log_date`, ${HOST} ERROR: Failed to determine age in seconds of current Nmon process, gaps may occur between Nmon collections"
				;;
				*)
					if [ $PIDAGE -gt $endtime ]; then
						echo "`log_date`, ${HOST} INFO: To prevent data gaps between 2 Nmon collections, a new process will be started, its PID will be available on next execution"

                        start_fifo_reader
                        sleep 1
                        start_nmon

						sleep 5 # Let nmon time to start
						# Relevant for Solaris Only		
						write_pid
					fi
				;;
				esac
			fi

			# Process found	
			echo "`log_date`, ${HOST} INFO: Nmon process is $PIDAGE sec old, a new process will be spawned when this value will be greater than estimated end in seconds ($endtime sec based on parameters)"
	
		fi

        # Prevent infinite spawn of nmon external snap processes (in case of unexpected issue)
        check_duplicated_external_snap

		echo "`log_date`, ${HOST} INFO: found Nmon running with PID ${SAVED_PID}"
		exit 0
		;;
		
	"false")
	
		# Process not found, Nmon has terminated or is not yet started		
		echo "`log_date`, ${HOST} INFO: Removing stale pid file (process not found)"
		rm -f ${PIDFILE}

        start_fifo_reader
        sleep 1
        start_nmon

		sleep 5 # Let nmon time to start
		# Relevant for Solaris Only		
		write_pid
		exit 0
		;;
	
	esac
	
	;;
	
	esac

fi

####################################################################
#############		End of Main Program 			############
####################################################################
