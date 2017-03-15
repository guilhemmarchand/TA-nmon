#!/bin/sh

# set -x

# Program name: fifo_consumer.sh
# Purpose - consume data produced by the fifo readers
# Author - Guilhem Marchand
# Disclaimer:  this provided "as is".
# Date - June 2014

# Version 1.0.0

# For AIX / Linux / Solaris

#################################################
## 	Your Customizations Go Here            ##
#################################################

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

# tmp file
temp_file="/tmp/fifo_consumer.sh.$$"

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

# Verify Perl availability (Perl will be more commonly available than Python)
PERL=`which perl >/dev/null 2>&1`

if [ $? -eq 0 ]; then
    INTERPRETER="perl"
else
    INTERPRETER="python"
fi

############################################
# functions
############################################

# consume function
consume_data () {

# fifo name (valid choices are: fifo1 | fifo2)
FIFO=$1

# consume fifo

# realtime
nmon_config=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_config.dat
nmon_header=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_header.dat
nmon_timestamp=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_timestamp.dat
nmon_data=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_data.dat

# rotated
nmon_config_rotated=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_config.dat.rotated
nmon_header_rotated=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_header.dat.rotated
nmon_timestamp_rotated=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_timestamp.dat.rotated
nmon_data_rotated=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_data.dat.rotated

# manage rotated data if existing, prevent any data loss

# all files must be existing to be managed
if [ -s $nmon_config_rotated ] && [ -s $nmon_header_rotated ] && [ -s $nmon_data_rotated ]; then

    # Ensure the first line of nmon_data starts by the relevant timestamp, if not add it
    head -1 $nmon_data_rotated | grep 'ZZZZ,T' >/dev/null
    if [ $? -ne 0 ]; then
        tail -1 $nmon_timestamp_rotated >$temp_file
        cat $nmon_config_rotated $nmon_header_rotated $temp_file $nmon_data_rotated | $SPLUNK_HOME/bin/splunk cmd $APP/bin/nmon2csv.sh --mode realtime
    else
        cat $nmon_config_rotated $nmon_header_rotated $nmon_data_rotated | $SPLUNK_HOME/bin/splunk cmd $APP/bin/nmon2csv.sh --mode realtime
    fi

    # remove rotated
    rm -f $SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/*.dat_rotated

fi

# Manage realtime files

# all files must be existing to be managed
if [ -s $nmon_config ] && [ -s $nmon_header ] && [ -s $nmon_data ]; then

    # get data mtime
    case $INTERPRETER in
    "perl")
        perl -e "\$mtime=(stat(\"$nmon_data\"))[9]; \$cur_time=time();  print \$cur_time - \$mtime;" >$temp_file
        nmon_data_mtime=`cat $temp_file`
        ;;

    "python")
        python -c "import os; import time; now = time.strftime(\"%s\"); print(int(int(now)-(os.path.getmtime('$nmon_data'))))" >$temp_file
        nmon_data_mtime=`cat $temp_file`
        ;;
    esac

    # file should have last mtime of mini 5 sec

    while [ $nmon_data_mtime -lt 5 ];
    do

        sleep 1

        # get data mtime
        case $INTERPRETER in
        "perl")
            perl -e "\$mtime=(stat(\"$nmon_data\"))[9]; \$cur_time=time();  print \$cur_time - \$mtime;" >$temp_file
            nmon_data_mtime=`cat $temp_file`
            ;;

        "python")
            python -c "import os; import time; now = time.strftime(\"%s\"); print(int(int(now)-(os.path.getmtime('$nmon_data'))))" >$temp_file
            nmon_data_mtime=`cat $temp_file`
            ;;
        esac


    done

    # Ensure the first line of nmon_data starts by the relevant timestamp, if not add it
    head -1 $nmon_data | grep 'ZZZZ,T' >/dev/null
    if [ $? -ne 0 ]; then
        tail -1 $nmon_timestamp >$temp_file
        cat $nmon_config $nmon_header $temp_file $nmon_data | $SPLUNK_HOME/bin/splunk cmd $APP/bin/nmon2csv.sh --mode realtime
    else
        cat $nmon_config $nmon_header $nmon_data | $SPLUNK_HOME/bin/splunk cmd $APP/bin/nmon2csv.sh --mode realtime
    fi

    # empty the nmon_data file
    > $nmon_data

fi

}

####################################################################
#############		Main Program 			############
####################################################################

# consume fifo1
consume_data fifo1

# allow 1 sec idle
sleep 1

# consume fifo2
consume_data fifo2

# remove the temp file
if [ -f $temp_file ]; then
    rm -f $temp_file
fi

exit 0
