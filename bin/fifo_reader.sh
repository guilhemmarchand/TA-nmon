#!/bin/sh

# set -x

# Program name: fifo_reader.sh
# Purpose - read nmon data from fifo file
# Author - Guilhem Marchand
# Disclaimer:  this provided "as is".
# Date - June 2014

# Version 1.3.33

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

# Var directory for data generation
APP_VAR=$SPLUNK_HOME/var/log/nmon

# Create directory if not existing already
[ ! -d $APP_VAR ] && { mkdir -p $APP_VAR; }

# Var directory for fifo output generation
FIFO_VAR=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/${FIFO}

# Create directory if not existing already
[ ! -d $FIFO_VAR ] && { mkdir -p $FIFO_VAR; }

# FIFO input
FIFO_INPUT=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/${FIFO}/nmon.fifo

# If the fifo does not yet exist, we are not ready to read
if [ ! -p $FIFO_INPUT ]; then
	echo "`date`, ${HOST} WARN, the fifo input file does exist yet ($FIFO_INPUT)"
	exit 1
fi

# Clean any existing dat file in the fifo directory
rm -f $SPLUNK_HOME/var/log/nmon/var/nmon_repository/${FIFO}/*.dat

while true
do
    if read line; then

        echo $line | egrep '^AAA|^BBB' >/dev/null
        if [ $? -eq 0 ]; then
            echo $line >> $FIFO_VAR/nmon_config.dat
        fi

        echo $line | egrep -v '^AAA|^BBB' | egrep -v 'T[0-9]{4,}' >/dev/null
        if [ $? -eq 0 ]; then
                echo $line >> $FIFO_VAR/nmon_header.dat
        fi

        echo $line | egrep -v '^AAA|^BBB' | egrep 'T[0-9]{4,}' >/dev/null
        if [ $? -eq 0 ]; then
            echo $line >> $FIFO_VAR/nmon_data.dat
        fi

    fi
done <"$FIFO_INPUT"
