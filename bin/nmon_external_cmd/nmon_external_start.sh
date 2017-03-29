#!/bin/sh

# Program name: nmon_external_start.sh
# Purpose - Add external command results to extend nmon data (header definition)
# Author - Guilhem Marchand
# Disclaimer:  this provided "as is".  
# Date - March 2017
# Guilhem Marchand 2017/03/18, initial version
# Guilhem Marchand 2017/03/29, protect against unexpecting failure in NMON_EXTERNAL_DIR getting value

# Version 1.0.01

# For AIX / Linux / Solaris

# for more information, see:
# https://www.ibm.com/developerworks/community/blogs/aixpert/entry/nmon_and_External_Data_Collectors?lang=en

# This script will define the headers for our custom external monitors
# The first field defines the name of the monitor (type field in the application)
# This monitor name must then be added to your local/nmonparser_config.json file

# 2 sections are available for nmon external monitor managements:
# - nmon_external: manage any number of fields without transposition
# - nmon_external_transposed: manage any number of fields with a notion of device / value

# Do no try to do anything unless the NMON_EXTERNAL_DIR variable has been correctly set
# we exit without any error code, the situation is not expected but we do not want to generate bad data in nmon data

if [ "$NMON_EXTERNAL_DIR" = "" ]
then
   exit 0
fi

# CAUTION: ensure your custom command does not output any comma within the field name and value

# number of running processes
echo "PROCCOUNT,Process Count,nb_running_processes" >>$NMON_EXTERNAL_DIR/nmon.fifo

# uptime information
echo "UPTIME,Server Uptime and load,uptime_stdout" >>$NMON_EXTERNAL_DIR/nmon.fifo
