# eventgen.conf

# The eventgen samples come from real system running in the IBM Power development plateform (PPD)
# performance data is generated in key value format via the TA-nmon-hec

# We provide 2 AIX servers and 2 Linux servers, 1 of each type runs  in CPU usage anomaly due to a load stress tool

# Deploy the Splunk eventgen from https://github.com/splunk/eventgen under $SPLUNK_HOME/etc/apps/SA-Eventgen
# Create an index called "nmon" and restart Splunk, data will immediately start to be available automatically

# Notes: Only performance and configuration data will be available

[nmon_performance_sample]
count = 100
mode = replay
index = nmon
sourcetype = nmon_data:fromhttp
source = perfdata:http
interval = 10
earliest = -1m
latest = now

## Replace timestamp
token.0.token = timestamp=\"(\d*)\"
token.0.replacementType = timestamp
token.0.replacement = %s

token.1.token = ZZZZ=\"(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})"
token.1.replacementType = timestamp
token.1.replacement = %Y-%m-%d %H:%M:%S

[nmon_config_sample]
count = 4
index = nmon
sourcetype = nmon_config:fromhttp
source = configdata:http
breaker = timestamp=\"([0-9]*)\"
# it does not work without:
bundlelines = true

## Replace timestamp
token.0.token = timestamp=\"([0-9]*)\"
token.0.replacementType = timestamp
token.0.replacement = %s

token.1.token = date=\"(\d{2}-\w{3}-\d{4}:\d{2}:\d{2}:\d{2})"
token.1.replacementType = timestamp
token.1.replacement = %d-%b-%Y:%H:%M:%S
