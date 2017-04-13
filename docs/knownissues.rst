############
Known Issues
############

Major or minor bug, enhancement requests will always be linked to an opened issue on the github project issue page:

https://github.com/guilhemmarchand/nmon-for-splunk/issues

Please note that once issues are considered as solved, by a new release or support exchanges, the issue will be closed. (but closed issues can still be reviewed)

**Current referenced issues:**

* **nmon external features on AIX 6.1 and AIX 7.2:**

In AIX 6.1 and AIX 7.1, the nmon external features might not work properly and stop after an arbitrary amount of time.

The root cause of the issue has not been found yet and is still under investigation.

The feature works however perfectly on AIX 7.2, any Linux OS and Solaris

* **fifo implementation not ready for Solaris on Sparc architectures:**

The sarmon binary for Sparc processor has not been released yet and is under compilation.

Once the binary will have been released, the TA-nmon using fifo will be compatible with Solaris Sparc processors.

* **local/nmon.conf will generate errors messages when deployed in search heads running in SHC (Search Head Clustering):**

Splunk has implemented an auto reformatting behavior in SHC deployer which makes an local/nmon.conf being incompatible with the TA-nmon.

As such, customizing the TA-nmon options using a local/nmon.conf from the SHC deployer will not work and generate numerous errors in splunkd on the search heads.

However, this does not impact the TA-nmon behaviors but the fact that you cannot use a local/nmon.conf for customization.

Note that you can still customize the options on a per server basis using a "/etc/nmon.conf" configuration file.

Git issue referenced: https://github.com/guilhemmarchand/TA-nmon/issues/23
