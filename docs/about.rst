######################################################################
About the TA-nmon, technical addon for Nmon Performance app for Splunk
######################################################################

* Author: Guilhem Marchand

* First release was published on starting 2014

* Purposes:

The TA-nmon for the Nmon Performance application for Splunk implements the excellent and powerful nmon binary known as Nigel's performance monitor.
Originally developed for IBM AIX performance monitoring and analysis, it is now an Open source project that made it available to many other systems.
It is fully available for any Linux flavor, and thanks to the excellent work of Guy Deffaux, it also available for Solaris 10/11 systems using the sarmon project.

The Nmon Performance monitor application for Splunk will generate performance and inventory data for your servers, and provides a rich number of monitors and tools to manage your AIX / Linux / Solaris systems.

.. image:: img/Octamis_Logo_v3_no_bg.png
   :alt: Octamis_Logo_v3_no_bg.png
   :align: right
   :target: http://www.octamis.com

**Nmon Performance is now associated with Octamis to provide professional solutions for your business, and professional support for the Nmon Performance solution.**

*For more information:*

---------------
Splunk versions
---------------

**The TA-nmon is compatible with any version of Splunk Enterprise 6.x and Splunk Universal Forwarder 6.x.**

---------------------
Index time operations
---------------------

The application operates index time operation, the PA-nmon_light add-on must be installed in indexers in order for the application to operate normally.

If there are any Heavy forwarders acting as intermediate forwarders between indexers and Universal Forwarders, the TA-nmon add-on must deployed on the intermediate forwarders to achieve successfully index time extractions.

------------------------------
About Nmon Performance Monitor
------------------------------

Nmon Performance Monitor for Splunk is provided in Open Source, you are totally free to use it for personal or professional use without any limitation,
and you are free to modify sources or participate in the development if you wish.

**Feedback and rating the application will be greatly appreciated.**

* Join the Google group: https://groups.google.com/d/forum/nmon-splunk-app

* App's Github page: https://github.com/guilhemmarchand/nmon-for-splunk

* Videos: https://www.youtube.com/channel/UCGWHd40x0A7wjk8qskyHQcQ

* Gallery: https://flic.kr/s/aHskFZcQBn
