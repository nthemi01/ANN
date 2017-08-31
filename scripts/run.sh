#!/bin/bash

# Main job running the training, 
# evaluation, etc. of the adversarial 
# neural network.
# --------------------------------------

# @TODO: 
# - Add commandline argument specifying config file
# - Add necessary checks
# -

# Settings
# ------------------
# Set name of job
#$ -N run
#
# Set to use current working directory
#$ -cwd
#
# Wait for staging job to finish
#$ -hold_jid stagein

# Specify requested amount of memory per core
#$ -l h_vmem=8G
#
# Specify requested number of compute cores
#$ -pe sharedmem 1
#
# Specify hard runtime limit
#$ -l h_rt=10:00:00

# Request 'gpu' parallel environment and N GPUs
#---$ -pe gpu 1
#---$ -l gpu=1

# Send mail to these users
#$ -M andreas.sogaard@ed.ac.uk
#
# Mail at beginning/end/on suspension
#$ -m bes

# Script
# ------------------
# Set up correct environment
echo "Setting up python environment"
. /etc/profile.d/modules.sh
#module load anaconda root/6.06.02
#source activate adversarial
. ./scripts/setup.sh

# Run python program
echo "Reading data from ${INPUTDIR}/*.root"
echo "Writing to ${OUTPUTDIR}/"
mkdir -p $OUTPUTDIR
echo ""

GROUPPATH=/exports/csce/eddie/ph/groups/PPE/asogaard
echo "Adding '$GROUPPATH' to PYTHONPATH"
export PYTHONPATH=$PYTHONPATH:$GROUPPATH
echo ""

echo "Running program"
./run.py -i $INPUTDIR -o $OUTPUTDIR | tee $OUTPUTDIR/log.txt
echo "Done"
