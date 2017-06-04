#!/usr/bin/env python

import os
import sys
import optparse
import logging
import re
import subprocess

# Releases Notes:

# - March 2017, V1.0.0: Guilhem Marchand, Initial version
# - 2017/04/01, V1.0.1: Guilhem Marchand, Update path discovery
# - 2017/06/03, V1.0.2: Guilhem Marchand, Update regular expr for headers extraction

# script version
version = '1.0.2'

#################################################
#      Variables
#################################################

# Set logging format
logging.root
logging.root.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(levelname)s %(message)s')
handler = logging.StreamHandler()
handler.setFormatter(formatter)
logging.root.addHandler(handler)

# Verify SPLUNK_HOME environment variable is available, the script is expected to be launched by Splunk
# which will set this.
# for debugging or manual run, please set this variable manually
try:
    os.environ["SPLUNK_HOME"]
except KeyError:
    logging.error(
        'The environment variable SPLUNK_HOME could not be verified, if you want to run this script manually you need'
        ' to export it before processing')
    sys.exit(1)

# SPLUNK_HOME environment variable
SPLUNK_HOME = os.environ['SPLUNK_HOME']

# APP_VAR directory
APP_VAR = SPLUNK_HOME + '/var/log/nmon/var'
if not os.path.exists(APP_VAR):
    logging.info(
        'The application var directory does not exist yet, we are not ready to start')
    sys.exit(0)

# APP Directories for TA-nmon
TA_NMON_APP = SPLUNK_HOME + '/etc/apps/TA-nmon'
TA_NMON_APP_CLUSTERED = SPLUNK_HOME + '/etc/slave-apps/TA-nmon'

# Empty APP
APP = ''

# Verify APP exist
if os.path.exists(TA_NMON_APP):
    APP = TA_NMON_APP
elif os.path.exists(TA_NMON_APP_CLUSTERED):
    APP = TA_NMON_APP_CLUSTERED
else:
    msg = 'The Application root directory could not be found, is the TA-nmon ? We tried: ' + \
          str(TA_NMON_APP) + ' ' + str(TA_NMON_APP_CLUSTERED)
    logging.error(msg)
    sys.exit(1)

# fifo_reader.sh
fifo_reader = APP + "/bin/fifo_reader.sh"

#################################################
#      Arguments
#################################################

parser = optparse.OptionParser(usage='usage: %prog [options]', version='%prog '+version)

parser.add_option('-F', '--fifo', action='store', type='string', dest='fifo_name',
                  help='set the fifo file to be read')
parser.add_option('--dumpargs', action='store_true', dest='dumpargs',
                  help='only dump the passed arguments and exit (for debugging purposes only)')

(options, args) = parser.parse_args()

if options.dumpargs:
    print("options: ", options)
    print("args: ", args)
    sys.exit(0)

if not options.fifo_name:
    logging.error(
        'The fifo file option has not been set (-F fifo_name or --fifo fifo_name)')
    sys.exit(1)
else:
    fifo_name = options.fifo_name

# define the full path to the fifo file
fifo_path = APP_VAR + '/nmon_repository/' + fifo_name + '/nmon.fifo'

# At startup, rotate any existing non empty .dat file if nmon_data.dat is not empty

# define the various files to be written

# realtime files
nmon_config_dat = APP_VAR + '/nmon_repository/' + fifo_name + '/nmon_config.dat'
nmon_header_dat = APP_VAR + '/nmon_repository/' + fifo_name + '/nmon_header.dat'
nmon_data_dat = APP_VAR + '/nmon_repository/' + fifo_name + '/nmon_data.dat'
nmon_timestamp_dat = APP_VAR + '/nmon_repository/' + fifo_name + '/nmon_timestamp.dat'
nmon_external_dat = APP_VAR + '/nmon_repository/' + fifo_name + '/nmon_external.dat'
nmon_dat = {nmon_config_dat, nmon_header_dat, nmon_timestamp_dat, nmon_data_dat, nmon_external_dat}

# Manage existing files and do the rotation if required
if os.path.exists(nmon_data_dat) and os.path.getsize(nmon_data_dat) > 0:
    for file in nmon_dat:
        rotated_file = str(file) + ".rotated"
        if os.path.isfile(rotated_file):
            os.remove(rotated_file)
        if os.path.isfile(file):
            os.rename(file, rotated_file)

elif os.path.exists(nmon_data_dat):
    for file in nmon_dat:
        if os.path.isfile(file):
            os.remove(file)

####################################################################
#           Main Program
####################################################################

# Verify the fifo file exists, and start processing
if not os.path.exists(fifo_path):
    logging.info(
        'The fifo file ' + fifo_path + ' does not exist yet, we are not ready to start')
    sys.exit(0)
else:
    # we use the fifo_reader.sh to read the fifo file, benchmarks have shown more stability than
    # opening the fifo file in pure Python
    cmd = fifo_reader + " " + fifo_path
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)

    while 1:
        line = p.stdout.readline()
        if line == '' and p.poll() != None:
            break

        # Manage nmon config
        nmon_config_match = re.match(r'^[AAA|BBB].+', line)
        nmon_header_match = re.match(r'^(?!AAA|BBB|TOP)[a-zA-Z0-9\-\_]*,(?!T\d{3,})[^,]*,(?!T\d{3,})[^,]*,.*', line)
        nmon_header_TOP_match = re.match(r'^TOP,(?!\d*,)', line)
        nmon_timestamp_match = re.match(r'^ZZZZ,T\d*', line)

        if nmon_config_match:
            with open(nmon_config_dat, "ab") as nmon_config:
                nmon_config.write(line)

        elif nmon_header_match:
            with open(nmon_header_dat, "ab") as nmon_header:
                nmon_header.write(line)

        elif nmon_header_TOP_match:
            with open(nmon_header_dat, "ab") as nmon_header:
                nmon_header.write(line)

        # timestamp management: write the nmon timestamp in nmon_data and as well nmon_timestamp for later use
        elif nmon_timestamp_match:
            with open(nmon_timestamp_dat, "ab") as nmon_timestamp:
                nmon_timestamp.write(line)
            with open(nmon_data_dat, "ab") as nmon_data:
                nmon_data.write(line)

        else:
            with open(nmon_data_dat, "ab") as nmon_data:
                nmon_data.write(line)
