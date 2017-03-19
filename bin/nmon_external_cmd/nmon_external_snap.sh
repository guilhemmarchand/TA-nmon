#!//bin/sh

# Program name: nmon_external_snap.sh
# Purpose - Add external command results to extend nmon data
# Author - Guilhem Marchand
# Disclaimer:  this provided "as is".  
# Date - March 2017
# Guilhem Marchand 2017/03/18, initial version

# Version 1.0.0

# For AIX / Linux / Solaris

# for more information, see:
# https://www.ibm.com/developerworks/community/blogs/aixpert/entry/nmon_and_External_Data_Collectors?lang=en

# This script will output the values for our custom external monitors
# The first field defines the name of the monitor (type field in the application)
# This monitor name must then be added to your local/nmonparser_config.json file

# 2 sections are available for nmon external monitor managements:
# - nmon_external: manage any number of fields without transposition
# - nmon_external_transposed: manage any number of fields with a notion of device / value

# CAUTION: ensure your custom command does not output any comma within the field name and value

# Number of running processes
/bin/echo -e "PROCCOUNT,$1,\c" >>$NMON_EXTERNAL_DIR/nmon.fifo
ps -ef | wc -l >>$NMON_EXTERNAL_DIR/nmon.fifo

# Uptime information (uptime command output)
/bin/echo -e "UPTIME,$1,\c" >>$NMON_EXTERNAL_DIR/nmon.fifo
echo "\"`uptime | sed 's/^\s//g' | sed 's/,/;/g'`\"" >>$NMON_EXTERNAL_DIR/nmon.fifo
