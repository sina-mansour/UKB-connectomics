#!/bin/bash
#SBATCH --account punim1566
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=0-06:00:00
#SBATCH --mem=4G
#SBATCH --partition=physical
#SBATCH -o /data/gpfs/projects/punim1566/UKB-slurm/slurm_logs/%x_%j.out

# This script is used for automated connectivity mapping for UKB
#
# Usage: ./automate.sh <subject-idx>
#

source /usr/local/module/spartan_new.sh
module load foss/2019b
module load web_proxy/latest connectomeworkbench/1.4.2 freesurfer/7.1.1-centos7_x86_64 fsl/6.0.3-python-3.7.4
# module load mrtrix/3.0.1-python-2.7.16 eigen/3.3.7

# ensure using the built mrtrix
export PATH="/data/gpfs/projects/punim1566/UKB-connectomics/lib/mrtrix3/bin:$PATH"

source ukbvenv/bin/activate

# make sure that the virtual environment is in pythonpath
[[ ":$PYTHONPATH:" != *":/data/gpfs/projects/punim1566/UKB-slurm/ukbvenv/lib/python3.7/site-packages:"* ]] && PYTHONPATH="/data/gpfs/projects/punim1566/UKB-slurm/ukbvenv/lib/python3.7/site-packages:${PYTHONPATH}"

# some colors for fancy logging :D
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# read the arguments
index=$1
extra=$2

# change directory to scripts directory
code_dir="/data/gpfs/projects/punim1566/UKB-connectomics"
# select where to store temporary files
# data_dir="/data/gpfs/projects/punim1566/UKB-download"
# instead, download to scratch space
# data_dir="/data/scratch/projects/punim1566/UKB-download"
# instead, use the ram disk storage space
# data_dir="/dev/shm/UKB-download"
# instead, use the fast local NVMe storage 
data_dir="/tmp/UKB-download"
mkdir -p ${data_dir}

cd ${code_dir}

# run the automation command
"${code_dir}/scripts/bash/UKB_connectivity_mapping_pipeline.sh" "${code_dir}" "${data_dir}" "${index}" "${extra}"

echo -e "${GREEN}[INFO]${NC} `date`: Script finished!"

deactivate

