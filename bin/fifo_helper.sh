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

# Which type of OS are we running
UNAME=`uname`

# Currently, the fifo mode is not available on Solaris OS
case $UNAME in
SunOS )
    # Don't do nothing and exit
    exit 0 ;;
esac

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

# Python is the default choice, if it is not available launch the Perl version
PYTHON=`which python >/dev/null 2>&1`

if [ $? -eq 0 ]; then

	# Supplementary check: Ensure Python is at least 2.7 version
	python_subversion=`python --version 2>&1`

	echo $python_subversion | grep '2.7' >/dev/null

	if [ $? -eq 0 ]; then
		INTERPRETER="python"
	else
		INTERPRETER="perl"
	fi

else

	INTERPRETER="perl"

fi

start_reader () {

FIFO=$1

# Verify that our fifo_reader are running, and start if required
ps -ef | egrep "fifo_reader\.p[l|y] -F ${FIFO}" | grep -v grep >/dev/null

if [ $? -ne 0 ]; then
    echo "`date`, ${HOST} INFO: starting the fifo_reader ${FIFO}"

    case $INTERPRETER in
    "python")
        $SPLUNK_HOME/etc/apps/TA-nmon/bin/fifo_reader.py -F ${FIFO} &
        ;;
    "perl")
        $SPLUNK_HOME/etc/apps/TA-nmon/bin/fifo_reader.pl -F ${FIFO} &
        ;;
    esac

else
    echo "`date`, ${HOST} INFO: The fifo_reader $FIFO is running"
fi

}

# Start our readers
start_reader fifo1
start_reader fifo2

exit 0
