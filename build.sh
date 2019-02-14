#!/usr/bin/env bash
# set -x

PWD=`pwd`
app=`basename $PWD`
version=`grep 'version =' ${app}/default/app.conf | awk '{print $3}' | sed 's/\.//g'`

tar -czf ${app}_${version}.tgz --exclude=TA-nmon/local --exclude=TA-nmon/metadata/local.meta --exclude=TA-nmon/bin/linux ${app}
echo "Wrote: ${app}_${version}.tgz"

exit 0
