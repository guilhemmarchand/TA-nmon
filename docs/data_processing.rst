####################
Nmon data processing
####################

====================
Generating Nmon data
====================

Generating the Nmon data which basically contains the performance measures and the configuration data is called "nmon_collect".

**The activity of the scripts involves in these operations is being logged by Splunk into:**

* sourcetype=nmon_collect: for standard output
* index=_internal sourcetype=splunkd: for stderr (unexpected errors)

**Most of these operations are done by the main script: bin/nmon_helper.sh:**

*************************************************
nmon_helper.sh tasks part1: initial startup tasks
*************************************************

.. image:: img/nmon_helper_part1.png
   :alt: nmon_helper_part1.png
   :align: center

**Steps are:**

* basics startup tasks: load SPLUNK_HOME variable, identify the application directories
* directory structure: load and verify directory structure, create if required in $SPLUNK_HOME/var/log/nmon
* binaries caching: for Linux OS only, verify if cache is existing and up to date, unpack linux.tgz to $SPLUNK_HOME/var/log/nmon if required
* start loading default and custom configurations

