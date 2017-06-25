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

# source default nmon.conf
if [ -f $APP/default/nmon.conf ]; then
    case $UNAME in
    Linux)
        # If this pattern is found, then the file needs to be corrected because it has been changed by the SHC deployer
        grep '[default]' $APP/default/nmon.conf >/dev/null
        if [ $? -eq 0 ]; then
            sed -i 's/ = /=/g' ${APP}/default/nmon.conf
            sed -i 's/\[default\]//g' ${APP}/default/nmon.conf
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

####################################################################
#############		Main Program 			############
####################################################################

# Store arguments sent to script
userargs=$@

###### Maintenance tasks ######

#
# Maintenance task1
#

# Maintenance task 1: verify if we have nmon processes running over the allowed period
# This issue seems to happen sometimes specially on AIX servers

# If an nmon process has not been terminated after its grace period, the process will be killed

# get the allowed runtime in seconds for an nmon process according to the configuration
# and add a 10 minute grace period

echo "`log_date`, ${HOST} INFO, starting maintenance task 1: verify nmon processes running over expected time period"

endtime=0

case ${mode_fifo} in
"1")
    endtime=`expr ${fifo_interval} \* ${fifo_snapshot}` ;;
*)
    endtime=`expr ${interval} \* ${snapshot}` ;;
esac

endtime=`expr ${endtime} + 600`

# get the list of running processes
ps -eo user,pid,command,etime,args | grep "nmon" | grep "splunk" | grep "var/log/nmon" | grep -v fifo_reader | grep -v grep >/dev/null

if [ $? -eq 0 ]; then

    oldPidList=`ps -eo user,pid,command,etime,args | grep "nmon" | grep "splunk" | grep "var/log/nmon" | grep -v fifo_reader | grep -v grep | awk '{ print $2 }'`
    for pid in $oldPidList; do

        pid_runtime=0
        # only run the process is running
        if [ -d /proc/${pid} ]; then
            # get the process runtime in seconds
            pid_runtime=`ps -p ${pid} -oetime= | tr '-' ':' | awk -F: '{ total=0; m=1; } { for (i=0; i < NF; i++) {total += $(NF-i)*m; m *= i >= 2 ? 24 : 60 }} {print total}'`
            if [ ${pid_runtime} -gt ${endtime} ]; then
                echo "`log_date`, ${HOST} WARN, old nmon process found due to `ps -eo user,pid,command,etime,args | grep $pid | grep -v grep` killing process $pid"
                kill $pid
            fi
        fi

    done

fi

#
# Maintenance task2
#
#set -x
# Maintenance task 2: An other case of issue we could have would be having the fifo_reader processing running without associated nmon processes
# In such a case, no new nmon processes would be launched and the collection would stop

echo "`log_date`, ${HOST} INFO, starting maintenance task 2: verify orphan fifo_reader processes"

for instance in fifo1 fifo2; do

# get the list of running processes
ps -eo user,pid,command,etime,args | grep "nmon" | grep "splunk" | grep fifo_reader | grep ${instance} >/dev/null

if [ $? -eq 0 ]; then

    oldPidList=`ps -eo user,pid,command,etime,args | grep "nmon" | grep "splunk" | grep fifo_reader | grep ${instance} | grep -v grep | awk '{ print $2 }'`

    # search for associated nmon process
    ps -eo user,pid,command,etime,args | grep "nmon" | grep "splunk" | grep "var/log/nmon" | grep -v fifo_reader | grep ${instance} >/dev/null

    if [ $? -ne 0 ]; then

        # no process found, kill the reader processes
        for pid in $oldPidList; do
                echo "`log_date`, ${HOST} WARN, orphan reader processes found (no associated nmon process) due to `ps -eo user,pid,command,etime,args | grep $pid | grep -v grep` killing process $pid"
                kill $pid
        done

    fi

fi

done

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
