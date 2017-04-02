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

# Version 1.0.10

# For AIX / Linux / Solaris

#################################################
## 	Your Customizations Go Here            ##
#################################################

if [ -z "${SPLUNK_HOME}" ]; then
	echo "`date`, ERROR, SPLUNK_HOME variable is not defined"
	exit 1
fi

# APP path discovery
if [ -d "$SPLUNK_HOME/etc/apps/TA-nmon" ]; then
        APP=$SPLUNK_HOME/etc/apps/TA-nmon

elif [ -d "$SPLUNK_HOME/etc/slave-apps/TA-nmon" ];then
        APP=$SPLUNK_HOME/etc/slave-apps/TA-nmon

else
        echo "`date`, ${HOST} ERROR, the APP directory could not be defined, is the TA-nmon installed ?"
        exit 1
fi

####################################################################
#############		Main Program 			############
####################################################################

# Store arguments sent to script
userargs=$@

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
