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
V1.3.18:
========

- fix: fifo mode implementation in parsers and several corrections #27
- fix: CIM compliance improvements and corrections
- feature: Allows deactivating fifo mode and switch to old mechanism via nmon.conf #26
- feature: Allows deactivating nmon external generation via nmon.conf #25

==============
V1.3.16 to 17:
==============

- unpublished intermediate releases

========
V1.3.15:
========

- Fix: nmon external load average extraction failure on some OS
- Fix: TA-nmon local/nmon.conf from the SHC deployer is not compatible #23
- Fix: Use the nmon var directory for fifo_consumer.sh temp file management
- Fix: solve nmon_external issues with AIX 6.1/7.1 (collection randomly stops)
- Fix: manage old topas-nmon version not compatible with -y option
- Feature: binaries for Ubuntu 17 (x86 32/64, power)

========
V1.3.14:
========

- intermediate version not published

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
