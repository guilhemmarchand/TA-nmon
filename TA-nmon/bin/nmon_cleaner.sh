#!/bin/sh

# set -x

# Program name: nmon_cleaner.sh
# Purpose - Frontal script to nmon_cleaner.py and nmon_cleaner.pl, will launch Python or Perl script depending on interpreter availability
#				See nmon_cleaner.py | nmon_cleaner.pl
# Author - Guilhem Marchand
# Disclaimer:  this provided "as is".  
# Date - February 2015
# Guilhem Marchand 2015/02/08, initial version
# Guilhem Marchand 2015/03/03, correction for script calling execution
# Guilhem Marchand 2015/03/10, Added Python 2.7.x version check before executing py script
# Guilhem Marchand 2015/03/11, /dev/null redirection for python version check step
# Guilhem Marchand 2015/03/20, python subversion check correction
# Guilhem Marchand 2015/07/27, hotfix for using the PA-nmon to generate Performance data in standalone indexers
# Guilhem Marchand 2016/02/08, /dev/null redirection improvement for the which python check
# Guilhem Marchand 2016/07/30, the core-app does not contains anymore data collection objects
# Guilhem Marchand 2016/08/02, Manage the TA-nmon_selfmode
# Guilhem Marchand 2017/04/02, Update path discovery
# Guilhem Marchand 2017/06/24,
#                               - specify explicit date format to prevent time zone issues
#                               - AIX maintenance task to solve non ending nmon processes issue

# Version 1.0.11

# For AIX / Linux / Solaris

#################################################
## 	Your Customizations Go Here            ##
#################################################

# format date output to strftime dd/mm/YYYY HH:MM:SS
log_date () {
    date "+%d-%m-%Y %H:%M:%S"
}

# hostname
HOST=`hostname`

if [ -z "${SPLUNK_HOME}" ]; then
	echo "`log_date`, ${HOST} ERROR, SPLUNK_HOME variable is not defined"
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

####################################################################
#############		Main Program 			############
####################################################################

# Store arguments sent to script
userargs=$@

###### Maintenance tasks ######

#AIX has a bug where sometimes the nmon processes fail to exit after a period of time
if [ `uname` = "AIX" ] ; then

  #If we find a process that has gone beyond 24 hours, and an additional 11 minutes grace period just in case
  res=`ps -eo user,pid,command,etime,args | grep "nmon" | grep "splunk" | grep "fifo" | awk '{ print $4 }' | grep "\-[0-9][0-9]:" | grep -v "\-00:1[01]" | grep -v grep`

  if [ "x$res" != "x" ]; then

        #Unfortunately under some circumstances there can by multiple old nmon processes that are stuck (not just the one)
        #Therefore will kill all of the splunk nmon processes to ensure things can continue

        oldPidList=`ps -eo user,pid,command,etime,args | grep "nmon" | grep "splunk" | grep "fifo" | grep "\-[0-9][0-9]:" | grep -v "\-00:1[01]" | awk '{ print $2 }' | grep -v grep`
        for pid in $oldPidList; do
            echo "`log_date`, ${HOST} WARN, old nmon process found due to `ps -eo user,pid,command,etime,args | grep $pid | grep -v grep` killing process $pid"
            kill $pid
        done

  fi

fi

###### End maintenance tasks ######

# Python is the default choice, if it is not available launch the Perl version
PYTHON=`which python >/dev/null 2>&1`

if [ $? -eq 0 ]; then

	# Supplementary check: Ensure Python is at least 2.7 version
	python_subversion=`python --version 2>&1`

	echo $python_subversion | grep '2.7' >/dev/null

	if [ $? -eq 0 ]; then
		$APP/bin/nmon_cleaner.py ${userargs}
	else
		$APP/bin/nmon_cleaner.pl ${userargs}
	fi
	
else

	$APP/bin/nmon_cleaner.pl ${userargs}

fi

exit 0
