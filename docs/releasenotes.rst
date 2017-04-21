#########################################
Release notes
#########################################

^^^^^^^^^^^^
Requirements
^^^^^^^^^^^^

* Splunk 6.x / Universal Forwarder v6.x and later Only

* Universal Forwarders clients system lacking a Python 2.7.x interpreter requires Perl WITH Time::HiRes module available

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
What has been fixed by release
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

========
V1.3.14:
========

- Fix: nmon external load average extraction failure on some OS
- Fix: TA-nmon local/nmon.conf from the SHC deployer is not compatible #23
- Feature: binaries for Ubuntu 17 (x86 32/64, power)

========
V1.3.13:
========

**This is a major release of the TA-nmon:**

- Feature: fantastic reduction of the system foot print (CPU,I/O,memory) with the new fifo implementation, the TA-nmon cost is now minimal!
- Feature: easily extend the native nmon data with any external data (OS commands, scripts of any kind, shell, perl, python...) in 2 lines of codes
- Feature: easily customize the list of performance monitors to be parsed (using the nmonparser_config.json)
- Feature: choose between legacy csv and json data generation (limited to Python compatible hosts), you can now choose to generate performance data in json format and prioritize storage over performance and licensing volume
- Feature: new dedicated documentation for the TA-nmon, https://readthedocs.org/projects/ta-nmon
- Feature: nmon binaries for Amazon Linux (AMI)
- Fix: Removal of recursive stanza in inputs.conf #21
- Fix: Increase the interval for nmon_cleaning #18
- Fix: Various corrections for Powerlinux (serial number identification, binaries and architecture identification)
- Fix: AIX rpm lib messages at nmon_helper.sh startup #22
- Various: deprecation of the TA-nmon_selfmode (now useless since the new release does use anymore the unarchive_cmd feature)

==================
Previous releases:
==================

**Please refer to:** http://nmon-for-splunk.readthedocs.io/en/latest/knownissues.html
