#!/bin/bash

# This script combines the codes from other scripts to run the complete connectivity
# mapping pipeline for a single UKBiobank subject.
#
# The pipeline mainly includes the following steps:
# - Generating individual volumetric atlases
# - Mapping functional time-series for the atlases
# - Mapping structural connectivity for the alases
# 
# Notes:
# - - the ${ukb_subjects_dir} must include a subdirectory for the subject id,
# 	- the code uses the fsaverage files provided by freesurfer, so freesurfer 
# 	  should be installed and $FREESURFER_HOME should be defined
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

main_dir=$1
ukb_subjects_dir=$2
ukb_subject_id=$3

script_dir="${main_dir}/scripts"
template_dir="${main_dir}/data/templates"
temporary_dir="${main_dir}/data/temporary"
output_dir="${main_dir}/data/output"

# create a directory to store temporary files
if [ ! -d "${temporary_dir}/${ukb_subject_id}" ]; then
	mkdir -p "${temporary_dir}/${ukb_subject_id}"
fi

# create a directory to store output files
if [ ! -d "${output_dir}/${ukb_subject_id}" ]; then
	mkdir -p "${output_dir}/${ukb_subject_id}"
fi

# --------------------------------------------------------------------------------
# List of all atlases
# --------------------------------------------------------------------------------

atlases=(
	# Glasser
	"Glasser,Q1-Q6_RelatedParcellation210.CorticalAreas_dil_Final_Final_Areas_Group_Colors.32k_fs_LR.dlabel.nii"
	# Gordon
	"Gordon,Gordon333.32k_fs_LR.dlabel.nii"
	# # Schaefer 7Networks
	# "Schaefer7n100p,Schaefer2018_100Parcels_7Networks_order.dlabel.nii"
	# "Schaefer7n200p,Schaefer2018_200Parcels_7Networks_order.dlabel.nii"
	# "Schaefer7n300p,Schaefer2018_300Parcels_7Networks_order.dlabel.nii"
	# "Schaefer7n400p,Schaefer2018_400Parcels_7Networks_order.dlabel.nii"
	# "Schaefer7n500p,Schaefer2018_500Parcels_7Networks_order.dlabel.nii"
	# "Schaefer7n600p,Schaefer2018_600Parcels_7Networks_order.dlabel.nii"
	# "Schaefer7n700p,Schaefer2018_700Parcels_7Networks_order.dlabel.nii"
	# "Schaefer7n800p,Schaefer2018_800Parcels_7Networks_order.dlabel.nii"
	# "Schaefer7n900p,Schaefer2018_900Parcels_7Networks_order.dlabel.nii"
	# "Schaefer7n1000p,Schaefer2018_1000Parcels_7Networks_order.dlabel.nii"
	# # Schaefer 17Networks
	# "Schaefer17n100p,Schaefer2018_100Parcels_17Networks_order.dlabel.nii"
	# "Schaefer17n200p,Schaefer2018_200Parcels_17Networks_order.dlabel.nii"
	# "Schaefer17n300p,Schaefer2018_300Parcels_17Networks_order.dlabel.nii"
	# "Schaefer17n400p,Schaefer2018_400Parcels_17Networks_order.dlabel.nii"
	# "Schaefer17n500p,Schaefer2018_500Parcels_17Networks_order.dlabel.nii"
	# "Schaefer17n600p,Schaefer2018_600Parcels_17Networks_order.dlabel.nii"
	# "Schaefer17n700p,Schaefer2018_700Parcels_17Networks_order.dlabel.nii"
	# "Schaefer17n800p,Schaefer2018_800Parcels_17Networks_order.dlabel.nii"
	# "Schaefer17n900p,Schaefer2018_900Parcels_17Networks_order.dlabel.nii"
	# "Schaefer17n1000p,Schaefer2018_1000Parcels_17Networks_order.dlabel.nii"
)

# --------------------------------------------------------------------------------
# Download subject data
# --------------------------------------------------------------------------------

# To be written...


# --------------------------------------------------------------------------------
# Generate native volumetric atlases
# --------------------------------------------------------------------------------

echo -e "${GREEN}[INFO]`date`:${NC} Mapping surface atlases to native space."

# copy files from fsaverage space
if [ ! -d "${template_dir}/freesurfer/fsaverage" ]; then
	mkdir -p "${template_dir}/freesurfer/"
	cp -r "${FREESURFER_HOME}/subjects/fsaverage" "${template_dir}/freesurfer/"
fi

# map all surface atlases to native surface
for atlas in ${atlases[@]}; do
	IFS=',' read -a atlas_info <<< "${atlas}"
	atlas_name=${atlas_info[0]}
	atlas_file=${atlas_info[1]}

	# map surface labels
	"${script_dir}/bash/label_map_fslr_to_fsaverage.sh" "${main_dir}" "${ukb_subjects_dir}" "${ukb_subject_id}" "${atlas_name}" "${atlas_file}"
done

echo -e "${GREEN}[INFO]`date`:${NC} Completed mapping surface atlases to native space."

# To be continued...


# --------------------------------------------------------------------------------
# Map functional time-series
# --------------------------------------------------------------------------------

# To be written...


# --------------------------------------------------------------------------------
# Map structural connectivity
# --------------------------------------------------------------------------------

# To be written...
