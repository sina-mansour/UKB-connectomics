#!/bin/bash

# this code is supposed to run in a high performance computing cluster login node with
# network access to initiate slurm jobs for execution of automated ukbiobank connectivity
# mapping. It will start submitting jobs to the queue for every instance. First, it checks
# if the required outputs are generated for that instance, if yes, then skips. If not,
# it then submits the appropriate job to the queue to generate required outputs.
#
# Usage: smart_run_automization.sh ...
#

# source /usr/local/module/spartan_new.sh
# module load foss/2019b
# module load web_proxy/latest connectomeworkbench/1.4.2 freesurfer/7.1.1-centos7_x86_64 fsl/6.0.3-python-3.7.4

# source ukbvenv/bin/activate

# # make sure that the virtual environment is in pythonpath
# [[ ":$PYTHONPATH:" != *":/data/gpfs/projects/punim1566/UKB-slurm/ukbvenv/lib/python3.7/site-packages:"* ]] && PYTHONPATH="/data/gpfs/projects/punim1566/UKB-slurm/ukbvenv/lib/python3.7/site-packages:${PYTHONPATH}"

# some colors for fancy logging :D
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}[INFO]${NC} `date`: Starting..."

start_index=$1
end_index=$(($2 + 1))

main_dir=$3
zip_file=$4 # tractography
required_file_list=$5

temporary_dir="${main_dir}/data/temporary"
output_dir="${main_dir}/data/output"

index=$start_index
end_line=$(($(< "${temporary_dir}/bulk/dwi,rsfc,surf,t1.combined" wc -l) + 1))
min_end=$(( end_index < end_line ? end_index : end_line ))
while [ $index -lt $min_end ]
do
        # Report index
        echo -e "${GREEN}[INFO]${NC} `date`: Checking files for: instance ${index}"

        # Map index to instance information from the combined bulk file
        subject_instance=(`sed "${index}q;d" "${temporary_dir}/bulk/dwi,rsfc,surf,t1.combined"`)

        ukb_subject_id=${subject_instance[0]}
        ukb_instance=${subject_instance[1]}

        echo -e "${GREEN}[INFO]${NC} `date`: Instance info: ${ukb_subject_id}_${ukb_instance}"

        # Check if required files are present
        needs_running=false


        files=(`${required_file_list}`)

        # check existence of all files
        for file in ${files[@]}; do
                # check if file exists in the compressed folder
                if [[ ! `unzip -Z1 "${output_dir}/subjects/${ukb_subject_id}_${ukb_instance}/${ukb_subject_id}_${zip_file}_${ukb_instance}.zip" | grep -w ${file}` ]]; then
                        echo -e "${RED}[INFO]${NC} File missing: ${file}"
                        needs_running=true
                        break
                fi
        done

        # Only submit required indices:
        if [ "${needs_running}" = true ] ; then
                sbatch --job-name="ukb_${index}_smart" --comment="UKB mapping pipeline, instance #${index}" automate.sh ${index}
                sleep 0.1
        fi

        ((index = index + 1))
done

echo -e "${GREEN}[INFO]${NC} `date`: All jobs submitted."

# deactivate
