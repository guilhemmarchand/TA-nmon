#################
Deployment Matrix
#################

What goes where ?
-----------------

* The TA-nmon is provided within the resources directory of the core application

* The TA-nmon is also available for download as an independent application in Splunk base: https://splunkbase.splunk.com/app/3248

**Standalone deployment: A single Splunk instance does all**

+------------------------+---------------+
| Splunk Instance        | TA-nmon       |
| (role)                 |               |
+========================+===============+
| Standalone             | X (optional)  |
+------------------------+---------------+

*The TA-nmon provides nmon performance and configuration collection for the host than runs the add-on, which is optional*

**Distributed deployment:**

+--------------------------------------------+---------------------+
| Splunk Instance                            | TA-nmon             |
| (role)                                     |                     |
+============================================+=====================+
| Search head (single instance or clustered) |    X (optional)     |
+--------------------------------------------+---------------------+
| Indexer (single instance or clustered)     |                     |
+--------------------------------------------+---------------------+
| Master node                                |    X (optional)     |
+--------------------------------------------+---------------------+
| Deployment servers                         |    X (optional)     |
+--------------------------------------------+---------------------+
| Heavy Forwarder                            |    X                |
+--------------------------------------------+---------------------+
| Universal Forwarder                        |    X                |
+--------------------------------------------+---------------------+

*The TA-nmon provides nmon performance and configuration collection for the host than runs the add-on, which is optional*
