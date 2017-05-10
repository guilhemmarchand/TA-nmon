#######
Upgrade
#######

Upgrading the TA-nmon is nothing more than reproducing the initial installation steps, basically uncompressing the content of the TA-nmon tgz archive.

**Please refer to the installation documentations:**

* Standalone deployment: http://nmon-for-splunk.readthedocs.io/en/latest/installation_standalone.html

* Distributed deployment: http://nmon-for-splunk.readthedocs.io/en/latest/installation_distributed.html

* Splunk Cloud deployment: http://nmon-for-splunk.readthedocs.io/en/latest/installation_splunkcloud.html

**Additional information:**

The TA-nmon has an internal procedure that will cache the "/bin" directory from::

    $SPLUNK_HOME/etc/apps/TA-nmon/bin

To::

    $SPLUNK_HOME/var/log/nmon/bin

This procedure is useful because:

* A deployment made the Splunk deployment server starts by first completely removing the entire TA-nmon removing, this would let running nmon processes orphan (for Linux and Solaris)
* In Search Head Cluster, a constantly running nmon process with the application directory would generate an error during the bundle publication

The cache directory will be updated every time the "app.conf" files in the application directory differs from the version in cache, and is operated by the "bin/nmon_helper.sh" script.
