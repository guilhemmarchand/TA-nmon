#!/bin/sh

# set -x

# Program name: fifo_consumer.sh
# Purpose - consume data produced by the fifo readers
# Author - Guilhem Marchand
# Disclaimer:  this provided "as is".
# Date - June 2014

# Guilhem Marchand 2017/03, initial version
# Guilhem Marchand 2017/04/01, Update path discovery
# Guilhem Marchand 2017/04/02, Solaris is now fifo compatible
# Guilhem Marchand 2017/04/15, Fix SHC deployer re-formatting default/nmon.conf
# Guilhem Marchand 2017/04/24, Use the nmon var directory in Splunk dir for temp creation
# Guilhem Marchand 2017/05/23, Integrate new fifo mode from parsers, fixed hard coded arguments
# Guilhem Marchand 2017/05/29, error in rotated files naming for purge rm command
# Guilhem Marchand 2017/05/30, improvements to prevent gaps in data
# Guilhem Marchand 2017/06/04, manage nmon external metrics in dedicated file
# Guilhem Marchand 2017/06/04, specify explicit date format to prevent time zone issues

# Version 1.0.10

# For AIX / Linux / Solaris

#################################################
## 	Your Customizations Go Here            ##
#################################################

# hostname
HOST=`hostname`

# Which type of OS are we running
UNAME=`uname`

# format date output to strftime dd/mm/YYYY HH:MM:SS
log_date () {
    date "+%d-%m-%Y %H:%M:%S"
}

if [ -z "${SPLUNK_HOME}" ]; then
	echo "`log_date`, ${HOST} ERROR, SPLUNK_HOME variable is not defined"
	exit 1
fi

# tmp dir and file
temp_dir="${SPLUNK_HOME}/var/log/nmon/tmp/"

if [ ! -d ${temp_dir} ]; then
    mkdir -p ${temp_dir}
fi

temp_file="${temp_dir}/fifo_consumer.sh.$$"

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

# Verify Perl availability (Perl will be more commonly available than Python)
PERL=`which perl >/dev/null 2>&1`

if [ $? -eq 0 ]; then
    INTERPRETER="perl"
else
    INTERPRETER="python"
fi

# default values relevant for our context
nmon2csv_options="--mode fifo"

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
nmon_data_tmp=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_data_tmp.dat
nmon_external=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_external.dat
nmon_external_header=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_external_header.dat


# rotated
nmon_config_rotated=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_config.dat.rotated
nmon_header_rotated=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_header.dat.rotated
nmon_timestamp_rotated=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_timestamp.dat.rotated
nmon_data_rotated=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_data.dat.rotated
nmon_external_rotated=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_external.dat.rotated
nmon_external_header_rotated=$SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/nmon_external_header.dat.rotated

# manage rotated data if existing, prevent any data loss

# all files must be existing to be managed
if [ -s $nmon_config_rotated ] && [ -s $nmon_header_rotated ] && [ -s $nmon_data_rotated ]; then

    # Manager headers
    unset nmon_header_files
    if [ -f $nmon_external_header_rotated ]; then
        nmon_header_files="$nmon_header_rotated $nmon_external_header_rotated"
    else
        nmon_header_files="$nmon_header_rotated"
    fi

    # Ensure the first line of nmon_data starts by the relevant timestamp, if not add it
    head -1 $nmon_data_rotated | grep 'ZZZZ,T' >/dev/null
    if [ $? -ne 0 ]; then
        # check timestamp dat exists before processing
        # there is no else possible, if the the timestamp data file does not exist, there is nothing we can do
        # and the parser will raise an error
        if [ -f $nmon_timestamp_rotated ]; then
            tail -1 $nmon_timestamp_rotated >$temp_file
            cat $nmon_config_rotated $nmon_header_files $temp_file $nmon_data_rotated $nmon_external_rotated | $SPLUNK_HOME/bin/splunk cmd $APP/bin/nmon2csv.sh $nmon2csv_options
        fi
    else
        cat $nmon_config_rotated $nmon_header_files $nmon_data_rotated $nmon_external_rotated | $SPLUNK_HOME/bin/splunk cmd $APP/bin/nmon2csv.sh $nmon2csv_options
    fi

    # remove rotated
    rm -f $SPLUNK_HOME/var/log/nmon/var/nmon_repository/$FIFO/*.dat.rotated

    # header var
    unset nmon_header_files

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

    # copy content
    cat $nmon_data > $nmon_data_tmp

    # nmon external data
    if [ -f $nmon_external ]; then
        cat $nmon_external >> $nmon_data_tmp
    fi

    # empty the nmon_data file & external
    > $nmon_data
    > $nmon_external

    # Manager headers
    unset nmon_header_files
    if [ -f $nmon_external_header ]; then
        nmon_header_files="$nmon_header $nmon_external_header"
    else
        nmon_header_files="$nmon_header"
    fi

    # Ensure the first line of nmon_data starts by the relevant timestamp, if not add it
    head -1 $nmon_data_tmp | grep 'ZZZZ,T' >/dev/null
    if [ $? -ne 0 ]; then
        tail -1 $nmon_timestamp >$temp_file
        cat $nmon_config $nmon_header_files $temp_file $nmon_data_tmp | $SPLUNK_HOME/bin/splunk cmd $APP/bin/nmon2csv.sh $nmon2csv_options
    else
        cat $nmon_config $nmon_header_files $nmon_data_tmp | $SPLUNK_HOME/bin/splunk cmd $APP/bin/nmon2csv.sh $nmon2csv_options
    fi

    # remove the copy
    rm -f $nmon_data_tmp

    # header var
    unset nmon_header_files

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
