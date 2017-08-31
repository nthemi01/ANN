#!/bin/bash

# @TODO:
# - Add 'gpu' argument
# - Add 'tensorflow' argument
# - Add 'config' argument

# Check if valid Kerberos ticket exists
KTICKET=`klist | grep /CERN.CH`
if [ -z "$KTICKET" ]; then
    echo "No valid Kerberos ticket was found. Please create one:"
    kinit -f asogaard@CERN.CH
else
    echo "Found a valid Kerberos ticket:"
    echo "  $KTICKET"
fi

# Get named lxplus node to use
rm -f .sshlog
ssh -v asogaard@lxplus.cern.ch > .sshlog 2>&1 3>&1 &
sleep 1
PID=`ps -u $USER | grep "ssh$" | sed 's/^ *//g' | sed 's/ .*//g'`
kill $PID
wait $PID 2>/dev/null
OUTPUT=`cat .sshlog`

if [ -z "$OUTPUT" ]; then
    echo "Got empty output from SSH"
    exit
fi

LXPLUS=`echo "$OUTPUT" | grep "Connecting to lxplus.cern.ch" | cut -d "[" -f2 | cut -d "]" -f1 | xargs host | sed 's/.*\(lxplus[0-9]*\).*/\1/g'`

if [ -z "$LXPLUS" ]; then
    echo "Got empty LXPLUS. Something went wrong in parsing the output from SSH."
    exit
else
    echo "Using lxplus node '${LXPLUS}'"
fi

# Copy kerberos ticket to current directory (to allow rsync + ssh to access it from cwd)
KCACHE=`echo $KRB5CCNAME | cut -d ":" -f2`
mkdir -p .kerberos
rm -f .kerberos/*
scp $KCACHE .kerberos/
KFILE=`echo $KCACHE | cut -d "/" -f3`

# Define common unique indicators
#VERSION=2017-06-22              # AnalysisTools outputObjdef cache
VERSION=2017-08-25-ANN

TIMESTAMP=`date +%Y-%m-%d_%H%M%S` # To uniquely distinguish runs

# Define common patch
EOS=asogaard@$LXPLUS.cern.ch:/eos/atlas/user/a/asogaard/Analysis/2016/BoostedJetISR/outputObjdef
DATASTORE=/exports/csce/datastore/ph/groups/PPE/atlas/users/$USER/adversarial
SCRATCH=/exports/eddie/scratch/$USER/adversarial

# Submit all jobs in the correct order with the necessary environment variables
qsub -v SOURCE=$EOS/$VERSION              -v DESTINATION=$SCRATCH/data            -v KRB5CCNAME=FILE:.kerberos/$KFILE scripts/stagein.sh
qsub -v INPUTDIR=$SCRATCH/data/$VERSION   -v OUTPUTDIR=$SCRATCH/output/$TIMESTAMP scripts/run.sh
qsub -v SOURCE=$SCRATCH/output/$TIMESTAMP -v DESTINATION=$DATASTORE/output        scripts/stageout.sh
