#!/bin/bash

# This script is be used to download all required files from UKB servers.
# 
# Helpful resources:
# 


# some colors for fancy logging :D
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


# --------------------------------------------------------------------------------
# Setting required variables
# --------------------------------------------------------------------------------

# files directory

main_dir=$1
ukb_subjects_dir=$2
ukb_subject_id=$3
ukb_instance=$4
working_dir=$5

script_dir="${main_dir}/scripts"
template_dir="${main_dir}/data/templates"
temporary_dir="${main_dir}/data/temporary"
output_dir="${main_dir}/data/output"



# --------------------------------------------------------------------------------
# Download subject data
# --------------------------------------------------------------------------------


echo -e "${GREEN}[INFO]`date`:${NC} Downloading required files (subject:${ukb_subject_id}, instance:${ukb_instance})."

# create a directory to store downloaded files
if [ ! -d "${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}" ]; then
	mkdir -p "${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}"
fi

# create a directory to store temporary files
if [ ! -d "${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}" ]; then
	mkdir -p "${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}"
fi

# create a directory to store output files
if [ ! -d "${output_dir}/subjects/${ukb_subject_id}_${ukb_instance}" ]; then
	mkdir -p "${output_dir}/subjects/${ukb_subject_id}_${ukb_instance}"
fi

# create a batch download file to get all imaging data for the subject and instance
rsfc_zip="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/${ukb_subject_id}_20227_${ukb_instance}.zip"
dwi_zip="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/${ukb_subject_id}_20250_${ukb_instance}.zip"
t1_zip="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/${ukb_subject_id}_20252_${ukb_instance}.zip"
surf_zip="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/${ukb_subject_id}_20263_${ukb_instance}.zip"
while [ ! -f ${rsfc_zip} ] || [ ! -f ${dwi_zip} ] || [ ! -f ${t1_zip} ] || [ ! -f ${surf_zip} ]; do
	
	echo -e "${GREEN}[INFO]`date`:${NC} Download required, files needed:"
	
	# give a bit of time before trying
	sleep $((1 + $RANDOM % 10))

	batch_file="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/download.batch"
	touch $batch_file
	> $batch_file
	# rsfc files
	if [ ! -f ${rsfc_zip} ]; then
		echo -e "${GREEN}[INFO]`date`:${NC} Download required, fMRI: ${ukb_subject_id} 20227_${ukb_instance}"
		echo "${ukb_subject_id} 20227_${ukb_instance}" >> $batch_file
	fi
	# dwi files
	if [ ! -f ${dwi_zip} ]; then
		echo -e "${GREEN}[INFO]`date`:${NC} Download required, dMRI: ${ukb_subject_id} 20250_${ukb_instance}"
		echo "${ukb_subject_id} 20250_${ukb_instance}" >> $batch_file
	fi
	# t1 files
	if [ ! -f ${t1_zip} ]; then
		echo -e "${GREEN}[INFO]`date`:${NC} Download required, T1: ${ukb_subject_id} 20252_${ukb_instance}"
		echo "${ukb_subject_id} 20252_${ukb_instance}" >> $batch_file
	fi
	# freesurfer files
	if [ ! -f ${surf_zip} ]; then
		echo -e "${GREEN}[INFO]`date`:${NC} Download required, FreeSurfer: ${ukb_subject_id} 20263_${ukb_instance}"
		echo "${ukb_subject_id} 20263_${ukb_instance}" >> $batch_file
	fi

	# download the batch (make sure .ukbkey is present and correct)
	cd "${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}"
	cp "${temporary_dir}/ukb/.ukbkey" .
	"${temporary_dir}/ukb/ukbfetch" -bdownload.batch -v
	rm ./.ukbkey
	cd "${working_dir}"
done

cd "${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}"
rsfc_dir="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/fMRI"
if [ ! -d ${rsfc_dir} ]; then
	echo -e "${GREEN}[INFO]`date`:${NC} Extracting download, fMRI (${rsfc_dir})."
	unzip ${rsfc_zip}
fi
dwi_dir="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/dMRI"
if [ ! -d ${dwi_dir} ]; then
	echo -e "${GREEN}[INFO]`date`:${NC} Extracting download, dMRI (${dwi_dir})."
	unzip ${dwi_zip}
fi
t1_dir="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/T1"
if [ ! -d ${t1_dir} ]; then
	echo -e "${GREEN}[INFO]`date`:${NC} Extracting download, T1 (${t1_dir})."
	unzip ${t1_zip}
fi
surf_dir="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/FreeSurfer"
if [ ! -d ${surf_dir} ]; then
	echo -e "${GREEN}[INFO]`date`:${NC} Extracting download, FreeSurfer (${surf_dir})."
	unzip ${surf_zip}
fi
cd "${working_dir}"
