#!/bin/bash

# This script combines the codes from other scripts to run the complete connectivity
# mapping pipeline for a single UKBiobank subject.
#
# The pipeline mainly includes the following steps:
# - Generating individual volumetric atlases
# - Mapping functional time-series for the atlases
# - Mapping structural connectivity for the alases
# 
# Usage:
# 	UKB_connectivity_mapping_pipeline.sh <path_to_codes_directory> <path_to_subject_directory> <subject_id>
# 
# Notes:
# - the ${ukb_subjects_dir} must include a subdirectory for the subject id,
# - the paths provided should not contain spaces (FSL issue)
# - the code uses the fsaverage files provided by freesurfer, so freesurfer 
# 	  should be installed and $FREESURFER_HOME should be defined
# 
# Helpful resources:
# 

# some colors for fancy logging :D
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# # loading required packages on spartan
# module load Python/3.6.4-intel-2017.u2
# source venv/bin/activate

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
if [ ! -d "${temporary_dir}/subjects/${ukb_subject_id}" ]; then
	mkdir -p "${temporary_dir}/subjects/${ukb_subject_id}"
fi

# create a directory to store output files
if [ ! -d "${output_dir}/subjects/${ukb_subject_id}" ]; then
	mkdir -p "${output_dir}/subjects/${ukb_subject_id}"
fi

# --------------------------------------------------------------------------------
# List of all atlases
# --------------------------------------------------------------------------------

atlases=(
	# Glasser
	"Glasser,Q1-Q6_RelatedParcellation210.CorticalAreas_dil_Final_Final_Areas_Group_Colors.32k_fs_LR.dlabel.nii"
	# # Schaefer 7Networks
	"Schaefer7n100p,Schaefer2018_100Parcels_7Networks_order.dlabel.nii"
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

subcortical_atlases=(
	# Melbourne Subcortex Atlas
	# "Tian_Subcortex_S1_3T,Tian_Subcortex_S1_3T.nii.gz"
	# "Tian_Subcortex_S2_3T,Tian_Subcortex_S2_3T.nii.gz"
	# "Tian_Subcortex_S3_3T,Tian_Subcortex_S3_3T.nii.gz"
	"Tian_Subcortex_S4_3T,Tian_Subcortex_S4_3T.nii.gz"
)

# --------------------------------------------------------------------------------
# Download subject data
# --------------------------------------------------------------------------------

# To be written...


# --------------------------------------------------------------------------------
# Generate native volumetric atlases
# --------------------------------------------------------------------------------

# Step 1: map surface atlases to native surface

echo -e "${GREEN}[INFO]`date`:${NC} Mapping surface atlases to native surface space."

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

echo -e "${GREEN}[INFO]`date`:${NC} Completed mapping surface atlases to native surface space."

# Step 2: map native surface atlases to native volumetric labels

echo -e "${GREEN}[INFO]`date`:${NC} Mapping native surface atlases to native volume."

# map all surface atlases to native volume
for atlas in ${atlases[@]}; do
	IFS=',' read -a atlas_info <<< "${atlas}"
	atlas_name=${atlas_info[0]}
	atlas_file=${atlas_info[1]}

	echo -e "${GREEN}[INFO]`date`:${NC} Mapping ${atlas_name} to native volume."

	# use the python code to map surface labels to native volume
	native_atlas_location="${temporary_dir}/subjects/${ukb_subject_id}/atlases/native.${atlas_name}.nii.gz"
	if [ ! -f ${native_atlas_location} ]; then
		python3 "${script_dir}/python/map_surface_label_to_volume.py" "${main_dir}" "${ukb_subjects_dir}" "${ukb_subject_id}" "${atlas_name}"
	fi

	# This native parcellation should now be resampled to the fmri space
	native_atlas_location_fMRI="${temporary_dir}/subjects/${ukb_subject_id}/atlases/native.fMRI_space.${atlas_name}.nii.gz"
	if [ ! -f ${native_atlas_location_fMRI} ]; then
		mri_vol2vol --mov "${native_atlas_location}" --targ "${ukb_subjects_dir}/${ukb_subject_id}/fMRI/rfMRI.ica/mean_func.nii.gz" --interp nearest --regheader --o "${native_atlas_location_fMRI}"
	fi
done

# Step 3: map subcortical labels from standard to native space

echo -e "${GREEN}[INFO]`date`:${NC} Mapping MNI subcortical atlases to native volume."

if [ ! -d "${temporary_dir}/subjects/${ukb_subject_id}/transforms" ]; then
	mkdir -p "${temporary_dir}/subjects/${ukb_subject_id}/transforms"
fi

# compute inverse warp required for warping labels to native
echo -e "${GREEN}[INFO]`date`:${NC} Computing the inverse warp."
inverse_warp="${temporary_dir}/subjects/${ukb_subject_id}/transforms/MNI_to_T1_inversed_warp_coef.nii.gz"
if [ ! -f ${inverse_warp} ]; then
	invwarp --ref="${ukb_subjects_dir}/${ukb_subject_id}/T1/T1_brain.nii.gz" --warp="${ukb_subjects_dir}/${ukb_subject_id}/T1/transforms/T1_to_MNI_warp_coef.nii.gz" --out="${inverse_warp}"
fi

# map all subcortical atlases to native volume
# mainly, we'll use the inverse warp to transform the subcortical atlas to native space
for atlas in ${subcortical_atlases[@]}; do
	IFS=',' read -a atlas_info <<< "${atlas}"
	atlas_name=${atlas_info[0]}
	atlas_file=${atlas_info[1]}

	echo -e "${GREEN}[INFO]`date`:${NC} Mapping ${atlas_name} to native volume."

	atlas_location="${template_dir}/atlases/${atlas_file}"

	# use FSL's applywarp to map subcortical labels to native volume
	native_atlas_location="${temporary_dir}/subjects/${ukb_subject_id}/atlases/native.${atlas_name}.nii.gz"
	if [ ! -f ${native_atlas_location} ]; then
		applywarp --ref="${ukb_subjects_dir}/${ukb_subject_id}/T1/T1_brain.nii.gz" --in="${atlas_location}" --warp="${inverse_warp}" --out="${native_atlas_location}" --interp=nn
	fi

	# This native parcellation should now be resampled to the fmri space
	native_atlas_location_fMRI="${temporary_dir}/subjects/${ukb_subject_id}/atlases/native.fMRI_space.${atlas_name}.nii.gz"
	if [ ! -f ${native_atlas_location_fMRI} ]; then
		mri_vol2vol --mov "${native_atlas_location}" --targ "${ukb_subjects_dir}/${ukb_subject_id}/fMRI/rfMRI.ica/mean_func.nii.gz" --interp nearest --regheader --o "${native_atlas_location_fMRI}"
	fi
done


# --------------------------------------------------------------------------------
# Map functional time-series
# --------------------------------------------------------------------------------

# To be written...


# --------------------------------------------------------------------------------
# Map structural connectivity
# --------------------------------------------------------------------------------

# To be written...

# deactivate
