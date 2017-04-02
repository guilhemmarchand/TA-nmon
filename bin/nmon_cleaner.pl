#!/usr/bin/perl

# Program name: nmon_cleaner.pl
# Compatibility: Perl x
# Purpose - Clean nmon and csv files when retention expired
# Author - Guilhem Marchand
# Date of first publication - December 2014

# Releases Notes:

# - December 2014, V1.0.0: Guilhem Marchand, Initial version
# - 28/12/2014, V1.1.0: Guilhem Marchand, rewritten version for Nmon Splunk App V1.5.0
# - 11/03/2015, V1.1.1: Guilhem Marchand, migration of var directory
# - 27/07/2015, V1.1.2: Guilhem Marchand, hotfix for using the PA-nmon to generate Performance data in standalone indexers
# - 30/07/2016: V1.1.3: Guilhem Marchand:
#                                         - the core-app does not contains anymore data collection objects
# - 30/07/2016: V1.1.4: Guilhem Marchand:
#                                         - Splunk certification requires $SPLUNK_HOME/var/log/ for files generation
# - 02/08/2016: V1.1.5: Guilhem Marchand:
#                                         - Manage the TA-nmon_selfmode
# - 03/17/2017: V1.1.6: Guilhem Marchand:
#                                         - Increasing default value for csv cleaning to 14320 seconds
#                                         - Include json cleaning
# - 04/01/2017: V1.1.7: Guilhem Marchand: Update path discovery

$version = "1.1.7";

use Time::Local;
use Time::HiRes;
use Getopt::Long;
use File::stat;    # use the object-oriented interface to stat

# LOGGING INFORMATION:
# - The program uses the standard logging Python module to display important messages in Splunk logs
# - Every message of the script will be indexed and accessible within Splunk splunkd logs

#################################################
##      Arguments Parser
#################################################

# Default values
my $CSV_REPOSITORY    = "csv_repository";
my $JSON_REPOSITORY    = "json_repository";
my $APP               = "";
my $CONFIG_REPOSITORY = "config_repository";
my $NMON_REPOSITORY   = "nmon_repository";
my $MAXSECONDS        = "";
my $verbose;

$result = GetOptions(
    "csv_repository=s"    => \$CSV_REPOSITORY,       # string
    "json_repository=s"    => \$JSON_REPOSITORY,     # string
    "config_repository=s" => \$CONFIG_REPOSITORY,    # string
    "nmon_repository=s"   => \$NMON_REPOSITORY,      # string
    "cleancsv"            => \$CLEANCSV,             # string
    "approot=s"           => \$APP,                  # string
    "maxseconds_csv=s"    => \$MAXSECONDS_CSV,       # string
    "maxseconds_nmon=s"   => \$MAXSECONDS_NMON,      # string
    "version"             => \$VERSION,              # flag
    "help"                => \$help                  # flag
);

# Show version
if ($VERSION) {
    print("nmon_clean.pl version $version \n");

    exit 0;
}

# Show help
if ($help) {

    print( "

Help for nmon_cleaner.pl:

In default configuration (eg. no options specified) the script will purge any nmon file (*.nmon) in default nmon_repository
        	
Available options are:
	
--cleancsv :Activate the purge of csv files from csv repository and config repository (see also options above)
--maxseconds_csv <value> :Set the maximum file retention in seconds for csv data, every files older than this value will be permanently removed
--maxseconds_json <value> :Set the maximum file retention in seconds for json data, every files older than this value will be permanently removed
--maxseconds_nmon <value> :Set the maximum file retention in seconds for nmon files, every files older than this value will be permanently removed
--approot <value> :Set a custom value for the Application root directory (default are: nmon / TA-nmon / PA-nmon)
--csv_repository <value> :Set a custom location for directory containing csv data (default: csv_repository)
--json_repository <value> :Set a custom location for directory containing json data (default: json_repository)
--config_repository <value> :Set a custom location for directory containing config data (default: config_repository)
--nmon_repository <value> :Set a custom location for directory containing nmon raw data (default: nmon_repository)
--version :Show current program version \n
"
    );

    exit 0;
}

#################################################
##      Parameters
#################################################

# Default values for CSV retention (4 hours less 1 minute)
my $MAXSECONDS_CSV_DEFAULT = 14320;

# Default values for CSV retention (4 hours less 1 minute)
my $MAXSECONDS_JSON_DEFAULT = 14320;

# Default values for NMON retention (1 day)
my $MAXSECONDS_NMON_DEFAULT = 86400;

#################################################
##      Functions
#################################################

#################################################
##      Program
#################################################

# Processing starting time
my $t_start = [Time::HiRes::gettimeofday];

# Local time
my $time = localtime;

# Default Environment Variable SPLUNK_HOME, this shall be automatically defined if as the script shall be launched by Splunk
my $SPLUNK_HOME = $ENV{SPLUNK_HOME};

# Verify SPLUNK_HOME definition
if ( not $SPLUNK_HOME ) {
    print(
"\n$time ERROR: The environment variable SPLUNK_HOME could not be verified, if you want to run this script manually you need to export it before processing \n"
    );
    die;
}

# Discover TA-nmon path
if ( length($APP) == 0 ) {

    if ( -d "$SPLUNK_HOME/etc/apps/TA-nmon" ) {
        $APP = "$SPLUNK_HOME/etc/apps/TA-nmon";
    }
    elsif ( -d "$SPLUNK_HOME/etc/slave-apps/TA-nmon" ) {
        $APP = "$SPLUNK_HOME/etc/slave-apps/TA-nmon";
    }

}

else {

    if ( !-d "$APP" ) {
        print(
"\n$time ERROR: The Application root directory could be verified using your custom setting: $APP \n"
        );
        die;
    }

}

# Verify existence of APP
if ( !-d "$APP" ) {
    print(
"\n$time ERROR: The Application root directory could not be found, is the TA-nmon installed ?\n"
    );
    die;
}

# var directories
my $APP_MAINVAR = "$SPLUNK_HOME/var/log/nmon";
my $APP_VAR = "$APP_MAINVAR/var";

if ( !-d "$APP_MAINVAR" ) {
    print(
"\n$time INFO: main var directory not found ($APP_MAINVAR),  no need to run.\n"
    );
    exit 0;
}


####################################################################
#############		Main Program
####################################################################

# check retention
if ( not "$MAXSECONDS_CSV" ) {
    $MAXSECONDS_CSV = $MAXSECONDS_CSV_DEFAULT;
}

if ( not "$MAXSECONDS_JSON" ) {
    $MAXSECONDS_JSON = $MAXSECONDS_JSON_DEFAULT;
}

# check retention
if ( not "$MAXSECONDS_NMON" ) {
    $MAXSECONDS_NMON = $MAXSECONDS_NMON_DEFAULT;
}

# Print starting message
print("$time Starting nmon cleaning:\n");
print("Splunk Root Directory $SPLUNK_HOME nmon_cleaner version: $version Perl version: $] \n");

# Set current epoch time
$epoc = time();

# If the csv switch is on, purge csv data

if ($CLEANCSV) {

    # Counter
    $count = 0;

    # CSV Items to clean
    @cleaning =
      ( "$APP_VAR/$CSV_REPOSITORY/*.csv", "$APP_VAR/$JSON_REPOSITORY/*.json", "$APP_VAR/$CONFIG_REPOSITORY/*.csv" );

    # Enter loop
    foreach $key (@cleaning) {

        @files = glob($key);

        foreach $file (@files) {
            if ( -f $file ) {

                # Get file timestamp
                my $file_timestamp = stat($file)->mtime;

                # Get difference
                my $timediff = $epoc - $file_timestamp;

                # If retention has expired
                if ( $timediff > $MAXSECONDS_CSV ) {

                    # information
                    print ("Max set retention of $MAXSECONDS_CSV seconds seconds expired for file: $file \n");

                    # purge file
                    unlink $file;

                    # Increment counter
                    $count++;
                }
            }
        }

        if ( $count eq 0 ) {
            print ("No files found in directory: $key, no action required. \n");        
        }
        else {
            print("INFO: $count files were permanently removed from $key \n");
        }    

    }
}

# Counter
$count = 0;

# NMON Items to clean
@cleaning = ("$APP_VAR/$NMON_REPOSITORY/*.nmon");

# Enter loop
foreach $key (@cleaning) {

    @files = glob($key);

    foreach $file (@files) {
        if ( -f $file ) {

            # Get file timestamp
            my $file_timestamp = stat($file)->mtime;

            # Get difference
            my $timediff = $epoc - $file_timestamp;

            # If retention has expired
            if ( $timediff > $MAXSECONDS_NMON ) {
            
                # information
                print ("Max set retention of $MAXSECONDS_NMON seconds seconds expired for file: $file \n");

                # purge file
                unlink $file;

                # Increment counter
                $count++;

            }

        }

    }

    if ( $count eq 0 ) {
        print ("No files found in directory: $key, no action required. \n");        
    }
    else {
        print("INFO: $count files were permanently removed from $key \n");
    }    

}

#############################################
#############  Main Program End 	############
#############################################

# Show elapsed time
my $t_end = [Time::HiRes::gettimeofday];
print "Elapsed time was: ",
  Time::HiRes::tv_interval( $t_start, $t_end ) . " seconds \n";

exit(0);
