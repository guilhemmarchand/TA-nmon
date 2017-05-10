#!/usr/bin/env python

# Program name: create_agent.py
# Compatibility: Python 2x
# Purpose - Create a customized version of the TA-nmon for the Splunk Nmon App, see https://apps.splunk.com/app/1753
# Author - Guilhem Marchand
# Disclaimer: Distributed on an "AS IS" basis
# Date of first publication - April 2015

# Licence:

# Copyright 2014 Guilhem Marchand

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Releases Notes:

# - April 2015, V1.0.0: Guilhem Marchand, Initial version
# - 2015/07/12, V1.0.02: Guilhem Marchand
#                      - Default configuration uses now the nmon2csv.sh wrapper which requires update of the script
# - 2015/07/28, V1.0.03: Guilhem Marchand
#                      - Use the new shell wrapper when no option is provided, or if it is explicitely provided
# - 2016/02/15, V1.0.04: Guilhem Marchand: Prevent Linux and Sarmon binaries from being modified
# - 2016/07/31, V1.0.05: Guilhem Marchand: TA-nmon is now named as tgz extension
# - 2016/08/06, V1.0.06: Guilhem Marchand: With the release of the TA-nmon_selfmode, prevent from extract it
# - 2017/03/01, V1.0.07: Guilhem Marchand: Add the --json_output option
# - 2017/03/15, V1.0.08: Guilhem Marchand: Manage options in nmon.conf
# - 2017/05/10, V1.0.09: Guilhem Marchand: Use the TA-nmon tgz archive instead of full nmon app core tgz archive

import sys
import os
import tarfile
import glob
import fnmatch
import argparse
import shutil

version = '1.0.09'

# ###################################################################
#############           Arguments Parser
####################################################################

# Define Arguments

parser = argparse.ArgumentParser()

parser.add_argument('-f', action='store', dest='INFILE',
                    help='Name of the TA-nmon tgz Archive file')

parser.add_argument('--indexname', action='store', dest='INDEX_NAME',
                    help='Customize the Application Index Name (default: nmon)')

parser.add_argument('--agentname', action='store', dest='TA_NMON',
                    help='Define the TA Agent name and root directory')

parser.add_argument('--agentmode', action='store', dest='agentmode',
                    help='Define the Data Processing mode, valid values are: shell,python,perl / Default'
                         ' value is shell')

parser.add_argument('--parsingmode', action='store', dest='parsingmode',
                    help='Define the Data Processing mode for performance data, valid values are: csv,json / Default'
                         ' value is csv')

parser.add_argument('--version', action='version', version='%(prog)s ' + version)

parser.add_argument('--debug', dest='debug', action='store_true')

parser.set_defaults(debug=False)

args = parser.parse_args()

# Set debug
if args.debug:
    debug = True

####################################################################
#############           Functions
####################################################################

# String replacement function
# Can be called by:
# findreplace(path, string_to_search, replace_by, file_extension)

def findreplace(directory, find, replace, filepattern):
    for path, dirs, files in os.walk(os.path.abspath(directory)):
        for filename in fnmatch.filter(files, filepattern):
            filepath = os.path.join(path, filename)

            # Prevents binaries modification
            if "bin/linux" in filepath:
                if debug:
                    print("file " + str(filename) + " is binary or binary related")
            elif "bin/sarmon" in filepath:
                if debug:
                    print("file " + str(filename) + " is binary or binary related")
            else:
                with open(filepath) as f:
                    s = f.read()
                s = s.replace(find, replace)
                with open(filepath, "w") as f:
                    f.write(s)


####################################################################
#############           Main Program
####################################################################

# Check Arguments
if len(sys.argv) < 2:
    print "\n%s" % os.path.basename(sys.argv[0])
    print "\nThis utility had been designed to allow creating customized agents for the Nmon Splunk Application," \
          " please follow these instructions:\n"
    print "- Download the current release of the TA-nmon App in Splunk Base: https://splunkbase.splunk.com/app/3248 or clone the git repository: https://github.com/guilhemmarchand/TA-nmon.git"
    print "- Ensure to have this Python script and the TGZ archive in the same directory"
    print "- Run the tool: ./create_agent.py and check for available options"
    print "- After the execution, a new agent package will have been created in the resources directory"
    print "- Extract its content to your Splunk deployment server, configure the server class, associated clients and" \
          " deploy the agent"
    print "- Don't forget to set the application to restart splunkd after deployment\n"
    sys.exit(0)

# Will expect in first Argument the name of the tgz Archive of the Application to be downloaded in Splunk Base
if not (args.INFILE):
    print "\nERROR: Please provide the tgz Archive file with -f statement\n"
    sys.exit(1)
else:
    infile = args.INFILE

# Will expect the customize name of the Splunk index, the default name of the index is "nmon"
if not (args.INDEX_NAME):
    print "INFO: No custom index name were provided, using default \"nmon\" name for index"
    index_name = "nmon"
else:
    index_name = args.INDEX_NAME

# Define Agent mode
if not (args.agentmode):
    agentmode = "shell"
else:
    agentmode = args.agentmode

# Define Parsing mode
if not (args.parsingmode):
    parsingmode = "csv"
else:
    parsingmode = args.parsingmode

# If the root directory of the TA-nmon is not defined, exit and show message
if not (args.TA_NMON):
    print "ERROR: You must specify the name of the agent package you want to create, and it must be different from" \
          " the default package TA-nmon"
    sys.exit(0)
else:
    ta_root_dir = args.TA_NMON

# Avoid naming the TA as nmon core application
if ta_root_dir == "nmon":
    print "ERROR: The TA package cannot have the name nmon to avoid collision with the core application configuration"
    sys.exit(1)

# Verify tgz Archive file exists
if not os.path.exists(infile):
    print ('ERROR: invalid file, could not find: ' + infile)
    sys.exit(1)

# Ensure the same package name does not already exist in current directory
if os.path.exists(ta_root_dir):
    print ('ERROR: A directory named ' + ta_root_dir + ' already exist in current directory, please remove it and'
                                                       ' restart')
    sys.exit(1)
elif os.path.exists(ta_root_dir + ".tgz"):
    print ('ERROR: A tgz archive named ' + ta_root_dir + ".tgz" + ' already exist in current directory, please'
                                                                  ' remove it and restart')
    sys.exit(1)

# Extract Archive
tar = tarfile.open(infile)
msg = 'Extracting tgz Archive: ' + infile
print (msg)
tar.extractall()
tar.close()

# Operate

# Get current directory
curdir = os.getcwd()

# Extract the TA-nmon default package in current directory

print ('INFO: Extracting Agent tgz resources Archives')

tgz_files = 'TA-nmon*.tgz'

for tgz in glob.glob(str(tgz_files)):

    # Don't manage the alternative TA-nmon_selfmode
    if not "TA-nmon_selfmode" in tgz:
        tar = tarfile.open(tgz)
        tar.extractall()
        tar.close()

# Rename the TA-nmon directory to match agent name

msg = 'INFO: Renaming TA-nmon default agent to ' + ta_root_dir
print (msg)

shutil.copytree('TA-nmon', ta_root_dir)

################# STRING REPLACEMENTS #################

# Replace the old agent name in files

# Achieve string replacements

print ('Achieving files transformation...')

search = 'TA-nmon'
replace = ta_root_dir
findreplace(ta_root_dir, search, replace, "*.sh")
findreplace(ta_root_dir, search, replace, "*.py")
findreplace(ta_root_dir, search, replace, "*.pl")
findreplace(ta_root_dir, search, replace, "*.conf")

print ('Done.')

# Change index name only if differs from default index name (nmon)
if index_name != "nmon":

    # Replace basic index calls
    print ('INFO: Customizing any reference to index name in files')

    search = 'index = nmon'
    replace = 'index = ' + index_name
    findreplace(ta_root_dir, search, replace, "*.conf")

################# AGENT MODE #################

# shell is default value, if set to python or perl create a custom local/props.conf with appropriate settings

if agentmode in ('python', 'perl'):
    os.mkdir(ta_root_dir + '/local')
    src = ta_root_dir + "/default/props.conf"
    dst = ta_root_dir + "/local/props.conf"
    shutil.copyfile(src,dst)

    f = ta_root_dir + "/local/props.conf"
    if agentmode == "python":
        with open(f,"w") as conf:
            stanza = "[source::.../*.nmon]\n"
            conf.write(stanza)
            if parsingmode in ('json'):
                stanza = "unarchive_cmd = $SPLUNK_HOME/etc/apps/" + ta_root_dir + "/bin/nmon2csv.py --json_output\n"
            else:
                stanza = "unarchive_cmd = $SPLUNK_HOME/etc/apps/" + ta_root_dir + "/bin/nmon2csv.py\n"
            conf.write(stanza)
            conf.write("\n")
            stanza = "[source::.../*.nmon.gz]\n"
            conf.write(stanza)
            stanza = "unarchive_cmd = $SPLUNK_HOME/etc/apps/" + ta_root_dir + "/bin/nmon2csv.py --json_output\n"
            conf.write(stanza)
    elif agentmode == "perl":
        with open(f,"w") as conf:
            stanza = "[source::.../*.nmon]\n"
            conf.write(stanza)
            stanza = "unarchive_cmd = $SPLUNK_HOME/etc/apps/" + ta_root_dir + "/bin/nmon2csv.pl\n"
            conf.write(stanza)
            conf.write("\n")
            stanza = "[source::.../*.nmon.gz]\n"
            conf.write(stanza)
            stanza = "unarchive_cmd = $SPLUNK_HOME/etc/apps/" + ta_root_dir + "/bin/nmon2csv.pl\n"
            conf.write(stanza)

elif agentmode in ('shell') and parsingmode in ('json'):
    os.mkdir(ta_root_dir + '/local')
    src = ta_root_dir + "/default/props.conf"
    dst = ta_root_dir + "/local/props.conf"
    shutil.copyfile(src,dst)

    f = ta_root_dir + "/local/props.conf"

    with open(f, "w") as conf:
        stanza = "[source::.../*.nmon]\n"
        conf.write(stanza)
        stanza = "unarchive_cmd = $SPLUNK_HOME/etc/apps/" + ta_root_dir + "/bin/nmon2csv.sh --json_output\n"
        conf.write(stanza)
        conf.write("\n")
        stanza = "[source::.../*.nmon.gz]\n"
        conf.write(stanza)
        stanza = "unarchive_cmd = $SPLUNK_HOME/etc/apps/" + ta_root_dir + "/bin/nmon2csv.sh --json_output\n"
        conf.write(stanza)

# Manage options for nmon.conf
if parsingmode in ('json'):
    src = ta_root_dir + "/default/nmon.conf"
    dst = ta_root_dir + "/local/nmon.conf"
    shutil.copyfile(src, dst)
    f = ta_root_dir + "/local/nmon.conf"
    with open(f, "w") as conf:
        stanza = "\n# Custom options for the fifo_consumer.sh\n"
        conf.write(stanza)
        stanza = "nmon2csv_options=\"--mode realtime" + " --json_output\"\n"
        conf.write(stanza)
        conf.write("\n")

# Don't use "with" statement in tar creation for Python 2.6 backward compatibility
tar_file = ta_root_dir + '.tgz'
out = tarfile.open(tar_file, mode='w:gz')

try:
    out.add(ta_root_dir)
finally:
    msg = 'INFO: ************* Tar creation done of: ' + tar_file + ' *************'
    print (msg)
    out.close()

# remove Agent directory
if os.path.isdir(ta_root_dir):
        shutil.rmtree(ta_root_dir)

print ('\n*** Agent Creation terminated: To install the agent: ***\n')
print (' - Upload the tgz Archive ' + tar_file + ' to your Splunk deployment server')
print (' - Extract the content of the TA package in $SPLUNK_HOME/etc/deployment-apps/')
print (' - Configure the Application (set splunkd to restart), server class and associated clients to push the new'
       ' package to your clients\n')

# END
print ('Operation terminated.\n')
sys.exit(0)
