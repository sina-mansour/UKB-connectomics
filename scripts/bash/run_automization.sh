#!/bin/bash

# this code is supposed to run in a high performance computing cluster login node with
# network access to initiate slurm jobs for execution of automated ukbiobank connectivity
# mapping.
#
# Usage: run_automization.sh ...
#

# module load intelpython/3.6.8-2019.2.066
# source venv/bin/activate

# some colors for fancy logging :D
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[INFO]${NC} `date`: Starting..."

start_index=$1
end_index=$(($2 + 1))

index=$start_index
while [ $index -lt $end_index ]
do
        echo -e "${GREEN}[INFO]${NC} `date`: Submitting job for: instance ${index}"
        sbatch --job-name="ukb_${index}" --comment="UKB mapping pipeline, instance #${index}" automate.sh ${index}
        sleep 0.1
        ((index = index + 1))
done

echo -e "${GREEN}[INFO]${NC} `date`: All jobs submitted."

# deactivate
