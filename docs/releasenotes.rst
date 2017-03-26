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
V1.3.04:
========

**This is a major release of the TA-nmon:**

- Major release of technical add-ons v1.3.0: fifo implementation (for AIX and Linux) drastically reduce the CPU and other resources footprint on client servers
- Extend Nmon data with the nmon_external scripts, just add you own monitor (Shell, Perl, Python, REST... whatever) and extend the content of nmon data to match your needs
- Customize in a persistent fashion the list of performance monitors to be parsed (using the nmonparser_config.json)
- Choose between legacy csv and json data generation: you can now choose to generate performance data in json format and prioritize storage over performance and licensing volume
- Removal of recursive stanza in inputs.conf #21
- Increase the interval for nmon_cleaning #18
- Correction of ID identification for PowerLinux)
- Correction of PowerLinux systems identification
