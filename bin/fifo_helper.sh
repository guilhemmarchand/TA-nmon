#!/bin/sh

# set -x

# Program name: fifo_helper.sh
# Purpose - start the fifo_reader.sh detached
# Author - Guilhem Marchand
# Disclaimer:  this provided "as is".
# Date - June 2014

# Version 1.0.0

# For AIX / Linux / Solaris

#################################################
## 	Your Customizations Go Here            ##
#################################################

# fifo to be read (valid choices are: fifo1 | fifo2
FIFO=$1

# hostname
HOST=`hostname`

if [ -z "${SPLUNK_HOME}" ]; then
	echo "`date`, ${HOST} ERROR, SPLUNK_HOME variable is not defined"
	exit 1
fi

# Splunk Home variable: This should automatically defined when this script is being launched by Splunk
# If you intend to run this script out of Splunk, please set your custom value here
SPL_HOME=${SPLUNK_HOME}

# Check SPL_HOME variable is defined, this should be the case when launched by Splunk scheduler
if [ -z "${SPL_HOME}" ]; then
	echo "`date`, ${HOST} ERROR, SPL_HOME (SPLUNK_HOME) variable is not defined"
	exit 1
fi

# Defined which APP we are running from (nmon / TA-nmon / TA-nmon_selfmode / PA-nmon)
if [ -d "$SPLUNK_HOME/etc/apps/TA-nmon" ]; then
        APP=$SPLUNK_HOME/etc/apps/TA-nmon

elif [ -d "$SPLUNK_HOME/etc/apps/TA-nmon_selfmode" ]; then
        APP=$SPLUNK_HOME/etc/apps/TA-nmon_selfmode

elif [ -d "$SPLUNK_HOME/etc/apps/PA-nmon" ];then
        APP=$SPLUNK_HOME/etc/apps/PA-nmon

elif [ -d "$SPLUNK_HOME/etc/slave-apps/_cluster" ];then
        APP=$SPLUNK_HOME/etc/slave-apps/PA-nmon

else
        echo "`date`, ${HOST} ERROR, the APP directory could not be defined, is TA-nmon / PA-nmon installed ?"
        exit 1

fi

# Verify that our fifo_reader are running, and start if required
ps -ef | grep 'fifo_reader.sh fifo1' | grep -v grep >/dev/null

if [ $? -ne 0 ]; then
    echo "`date`, ${HOST} INFO: starting the fifo_reader fifo1"
    $SPLUNK_HOME/etc/apps/TA-nmon/bin/fifo_reader.sh fifo1 &
else
    echo "`date`, ${HOST} INFO: The fifo_reader fifo1 is running"
fi

# Verify that our fifo_reader are running, and start if required
ps -ef | grep 'fifo_reader.sh fifo2' | grep -v grep >/dev/null

if [ $? -ne 0 ]; then
    echo "`date`, ${HOST} INFO: starting the fifo_reader fifo2"
    $SPLUNK_HOME/etc/apps/TA-nmon/bin/fifo_reader.sh fifo2 &
else
    echo "`date`, ${HOST} INFO: The fifo_reader fifo2 is running"
fi

exit 0
