##############
Pre-requisites
##############

**The pre-requisites to run the TA-nmon are quite simple:**

* Python 2.7.x interpreter

By default, the TA-nmon tries to use the locally available Python 2.7.x interpreter.

Note that Splunk Enterprise embeds its own Python 2.7.x interpreter.

* Perl 5.x or higher with perl-Time-HiRes

If Python 2.7.x is not available in your systems (very likely on AIX, likely on old Linux and Solaris flavours), the TA-nmon will fall back to Perl.

In such a case, the Perl module "perl-Time-HiRes" must be installed, this can be the case on many systems (AIX does) but some may not have it installed by default.
