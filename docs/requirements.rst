##############
Pre-requisites
##############

-------------------
Splunk requirements
-------------------

**Compatibility matrix:**

+--------------------------------------------+----------------------+
| Metricator for Nmon stack                  | Major version branch |
|                                            |                      |
+============================================+======================+
| Splunk Universal Forwarder 6.x, 7.x        |      Version 1.x     |
+--------------------------------------------+----------------------+

-----------------------------
Technical Add-on requirements
-----------------------------

Operating system
^^^^^^^^^^^^^^^^

**The Technical Add-on is compatible with:**

- Linux OS X86 in 32/64 bits, PowerPC (PowerLinux), s390x (ZLinux), ARM
- IBM AIX 7.1 and 7.2
- Oracle Solaris 11

Third party software and libraries
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To operate as expected, the Technical Add-ons requires a Python **OR** a Perl environment available on the server:

**Python environment: used in priority**

+--------------------------------------------+----------------------+
| Requirement                                | Version              |
|                                            |                      |
+============================================+======================+
| Python interpreter                         | 2.7.x                |
+--------------------------------------------+----------------------+


**Perl environment: used only in fallback**

+--------------------------------------------+----------------------+
| Requirement                                | Version              |
|                                            |                      |
+============================================+======================+
| Perl interpreter                           | 5.x                  |
+--------------------------------------------+----------------------+
| Time::HiRes module                         | any                  |
+--------------------------------------------+----------------------+

**In addition, the Technical Addon requires:**

+--------------------------------------------+----------------------+
| Requirement                                | Version              |
|                                            |                      |
+============================================+======================+
| curl                                       | Any                  |
+--------------------------------------------+----------------------+


**Notes:**

- IBM AIX does not generally contain Python. Nevertheless, Perl is available as a standard. More, Time::HiRes is part of Perl core modules.
- Modern Linux distribution generally have Python version 2.7.x available and do not require any further action.
- Linux distributions lacking Python will fallback to Perl and must satisfy the Perl modules requirements.
- If running on a full Splunk instance (any Splunk dedicated machine running Splunk Enterprise), the Technical Add-on uses Splunk built-in Python interpreter.
