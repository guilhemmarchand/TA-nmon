#!//bin/sh

# Program name: nmon_external_start.sh
# Purpose - Add external command results to extend nmon data (header definition)
# Author - Guilhem Marchand
# Disclaimer:  this provided "as is".  
# Date - March 2017
# Guilhem Marchand 2017/03/18, initial version

# Version 1.0.0

# For AIX / Linux / Solaris

# for more information, see:
# https://www.ibm.com/developerworks/community/blogs/aixpert/entry/nmon_and_External_Data_Collectors?lang=en

# This script will define the headers for our custom external monitors
# The first field defines the name of the monitor (type field in the application)
# This monitor name must then be added to your local/nmonparser_config.json file

# 2 sections are available for nmon external monitor managements:
# - nmon_external: manage any number of fields without transposition
# - nmon_external_transposed: manage any number of fields with a notion of device / value

# CAUTION: ensure your custom command does not output any comma within the field name and value

# number of running processes
echo "PROCCOUNT,Process Count,nb_running_processes" >>$NMON_EXTERNAL_DIR/nmon.fifo

# uptime information
echo "UPTIME,Server Uptime and load,uptime_stdout" >>$NMON_EXTERNAL_DIR/nmon.fifo
