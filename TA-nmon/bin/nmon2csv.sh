#!/bin/sh

# set -x

# Program name: nmon2csv.sh
# Purpose - Frontal script to nmon2csv, will launch Python or Perl script depending on interpreter availability
#				See nmon2csv.py | nmon2csv.pl
# Author - Guilhem Marchand
# Disclaimer:  this provided "as is".  
# Date - February 2015
# Guilhem Marchand 2015/07/07, initial version
# - 07/27/2015, V1.0.01: Guilhem Marchand:
#                                         - hotfix for using the PA-nmon to generate Performance data in standalone indexers
# - 09/29/2015, V1.0.02: Guilhem Marchand:
#                                         - Restrict to Python 2.7.x to use nmon2csv.py
# - 10/14/2015, V1.0.03: Guilhem Marchand:
#                                         - Use $SPLUNK_HOME/var/run/nmon for temp directory instead of /tmp
# - 10/28/2015, V1.0.04: Guilhem Marchand:
#                                         - Fixed temp directory lacking creation if dir does not yet exist
# - 01/15/2016, V1.0.05: Guilhem Marchand:
#                                         - Send arguments from sh wrapper to nmon2csv parsers
# - 02/08/2016, V1.0.06: Guilhem Marchand:
#                                         - /dev/null redirection improvement for the which python check
# - 07/30/2016: V1.0.07: Guilhem Marchand:
#                                         - the core-app does not contains anymore data collection objects
# - 07/30/2016: V1.0.08: Guilhem Marchand:
#                                         - Splunk certification requires $SPLUNK_HOME/var/log/ for files generation
# - 08/02/2016: V1.0.09: Guilhem Marchand:
#                                         - Manage the TA-nmon_selfmode
# - 01/04/2017: V1.0.10: Guilhem Marchand:
#                                         - Update path discovery
# - 23/05/2017: V1.0.11: Guilhem Marchand:
#                                         - Missing userargs call in condition
# - 24/06/2017: V1.0.12: Guilhem Marchand:
#                                         - specify explicit date format to prevent time zone issues
# - 26/06/2017: V1.0.13: Guilhem Marchand:
#                                         - Interpreter choice update
# - 30/07/2017: V1.0.14: Guilhem Marchand:
#                                         - HOST variable is unset

# Version 1.0.14

# For AIX / Linux / Solaris

#################################################
## 	Your Customizations Go Here            ##
#################################################

# format date output to strftime dd/mm/YYYY HH:MM:SS
log_date () {
    date "+%d-%m-%Y %H:%M:%S"
}

# Set host
HOST=`hostname`

if [ -z "${SPLUNK_HOME}" ]; then
	echo "`log_date`, ERROR, SPLUNK_HOME variable is not defined"
	exit 1
fi

# Set tmp directory
APP_VAR=${SPLUNK_HOME}/var/log/nmon

# Verify it exists
if [ ! -d ${APP_VAR} ]; then
    mkdir -p ${APP_VAR}
	exit 1
fi

# silently remove tmp file (testing exists before rm seems to cause trouble on some old OS)
rm -f ${APP_VAR}/nmon2csv.temp.*

# Set nmon_temp
nmon_temp=${APP_VAR}/nmon2csv.temp.$$

# APP path discovery
if [ -d "$SPLUNK_HOME/etc/apps/TA-nmon" ]; then
        APP=$SPLUNK_HOME/etc/apps/TA-nmon

elif [ -d "$SPLUNK_HOME/etc/slave-apps/TA-nmon" ];then
        APP=$SPLUNK_HOME/etc/slave-apps/TA-nmon

else
        echo "`log_date`, ${HOST} ERROR, the APP directory could not be defined, is the TA-nmon installed ?"
        exit 1
fi

#
# Interpreter choice
#

PYTHON=0
PERL=0
# Set the default interpreter
INTERPRETER="python"

# Get the version for both worlds
PYTHON=`which python >/dev/null 2>&1`
PERL=`which perl >/dev/null 2>&1`

case $PYTHON in
*)
   python_subversion=`python --version 2>&1`
   case $python_subversion in
   *" 2.7"*)
    PYTHON_available="true" ;;
   *)
    PYTHON_available="false"
   esac
   ;;
0)
   PYTHON_available="false"
   ;;
esac

case $PERL in
*)
   PERL_available="true"
   ;;
0)
   PERL_available="false"
   ;;
esac

case `uname` in

# AIX priority is Perl
"AIX")
     case $PERL_available in
     "true")
           INTERPRETER="perl" ;;
     "false")
           INTERPRETER="python" ;;
 esac
;;

# Other OS, priority is Python
*)
     case $PYTHON_available in
     "true")
           INTERPRETER="python" ;;
     "false")
           INTERPRETER="perl" ;;
     esac
;;
esac

####################################################################
#############		Main Program 			############
####################################################################

# Store arguments sent to script
userargs=$@

# Store stdin
while read line ; do
	echo "$line" >> ${nmon_temp}
done

# Start the parser
case ${INTERPRETER} in

"python")
    cat ${nmon_temp} | ${SPLUNK_HOME}/bin/splunk cmd ${APP}/bin/nmon2csv.py ${userargs} ;;

"perl")
	cat ${nmon_temp} | ${SPLUNK_HOME}/bin/splunk cmd ${APP}/bin/nmon2csv.pl ${userargs} ;;

esac

# Remove temp
rm -f ${nmon_temp}

exit 0
