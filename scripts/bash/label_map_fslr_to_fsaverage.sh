#!/bin/bash

# This script can be used to map the HCP parcellation from the fsLR surface
# to freesurfer native surface.
# 
# Helpful resources:
# https://figshare.com/articles/dataset/HCP-MMP1_0_projected_on_fsaverage/3498446?file=5528816
# https://www.mail-archive.com/hcp-users%40humanconnectome.org/msg02890.html
# https://www.mail-archive.com/hcp-users%40humanconnectome.org/msg02467.html
# https://github.com/Washington-University/HCPpipelines/tree/master/global/templates/standard_mesh_atlases
# https://figshare.com/articles/dataset/HCP-MMP1_0_volumetric_NIfTI_masks_in_native_structural_space/4249400
# https://cjneurolab.org/2016/11/22/hcp-mmp1-0-volumetric-nifti-masks-in-native-structural-space/
# https://freesurfer.net/fswiki/mri_surf2surf
# https://community.mrtrix.org/t/missing-nodes-in-parcellation-image/4387


# Other considerations...
# There are two atlas glasser files (parcellation, validation), the parcellation
# file is used in this code.

# some colors for fancy logging :D
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


# --------------------------------------------------------------------------------
# Setting required variables
# --------------------------------------------------------------------------------

# files directory
# modify this to refere to where the subject data is stored at
# the ralative maps may need to be redefined to apply to UKB directory structure

main_dir=$1
ukb_subjects_dir=$2
ukb_subject_id=$3
ukb_instance=$4
atlas_name=$5
atlas_file=$6
atlas_space=$7

script_dir="${main_dir}/scripts"
template_dir="${main_dir}/data/templates"
temporary_dir="${main_dir}/data/temporary"

fsaverage_dir="${template_dir}/freesurfer/fsaverage"

echo -e "${GREEN}[INFO]`date`:${NC} Atlas: ${atlas_name}"
echo -e "${GREEN}[INFO]`date`:${NC} File name: ${atlas_file}"


left_fsaverage164_atlas_fs="${temporary_dir}/atlases/lh.fsaverage164.${atlas_name}.annot"
right_fsaverage164_atlas_fs="${temporary_dir}/atlases/rh.fsaverage164.${atlas_name}.annot"

left_native_atlas_fs="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/atlases/lh.native.${atlas_name}.annot"
right_native_atlas_fs="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/atlases/rh.native.${atlas_name}.annot"

if [ "${atlas_space}" == "fsLR" ]; then
	echo -e "${GREEN}[INFO]`date`:${NC} Starting to map fsLR label to fsnative"

	# --------------------------------------------------------------------------------
	# Convert dlabel files to label.gii format
	# --------------------------------------------------------------------------------

	atlas_label="${template_dir}/atlases/${atlas_file}"

	if [ ! -d "${temporary_dir}/atlases" ]; then
		mkdir -p "${temporary_dir}/atlases"
	fi

	left_atlas_gii="${temporary_dir}/atlases/${atlas_name}.L.32k_fs_LR.label.gii"
	if [ ! -f ${left_atlas_gii} ]; then
		wb_command -cifti-separate "${atlas_label}" COLUMN -label CORTEX_LEFT "${left_atlas_gii}"
	fi

	right_atlas_gii="${temporary_dir}/atlases/${atlas_name}.R.32k_fs_LR.label.gii"
	if [ ! -f ${right_atlas_gii} ]; then
		wb_command -cifti-separate "${atlas_label}" COLUMN -label CORTEX_RIGHT "${right_atlas_gii}"
	fi

	echo -e "${GREEN}[INFO]`date`:${NC} Atlas converted to .gii format."

	# --------------------------------------------------------------------------------
	# Convert fsaverage spheres to .gii format
	# --------------------------------------------------------------------------------

	left_fsaverage_sphere_fs="${fsaverage_dir}/surf/lh.sphere"
	right_fsaverage_sphere_fs="${fsaverage_dir}/surf/rh.sphere"

	if [ ! -d "${temporary_dir}/surf" ]; then
		mkdir -p "${temporary_dir}/surf"
	fi

	left_fsaverage_sphere_gii="${temporary_dir}/surf/lh.sphere.fsaverage.surf.gii"
	if [ ! -f ${left_fsaverage_sphere_gii} ]; then
		mris_convert "${left_fsaverage_sphere_fs}" "${left_fsaverage_sphere_gii}"
	fi

	right_fsaverage_sphere_gii="${temporary_dir}/surf/rh.sphere.fsaverage.surf.gii"
	if [ ! -f ${right_fsaverage_sphere_gii} ]; then
		mris_convert "${right_fsaverage_sphere_fs}" "${right_fsaverage_sphere_gii}"
	fi

	echo -e "${GREEN}[INFO]`date`:${NC} The fsaverage spheres converted to .gii format."

	# --------------------------------------------------------------------------------
	# Resample atlas labels from fsLR to fsaverage
	# --------------------------------------------------------------------------------

	if [ ! -d "${temporary_dir}/atlases" ]; then
		mkdir -p "${temporary_dir}/atlases"
	fi

	left_fsLR32k_gii="${template_dir}/surfaces/L.sphere.32k_fs_LR.surf.gii"
	right_fsLR32k_gii="${template_dir}/surfaces/R.sphere.32k_fs_LR.surf.gii"

	left_fsLR_to_fsaverage164="${template_dir}/surfaces/fs_L-to-fs_LR_fsaverage.L_LR.spherical_std.164k_fs_L.surf.gii"
	right_fsLR_to_fsaverage164="${template_dir}/surfaces/fs_R-to-fs_LR_fsaverage.R_LR.spherical_std.164k_fs_R.surf.gii"

	left_fsaverage164_atlas_gii="${temporary_dir}/atlases/fsaverage164.L.${atlas_name}.label.gii"
	if [ ! -f ${left_fsaverage164_atlas_gii} ]; then
		wb_command -label-resample "${left_atlas_gii}" "${left_fsLR32k_gii}" "${left_fsLR_to_fsaverage164}" BARYCENTRIC \
				   "${left_fsaverage164_atlas_gii}"
	fi

	right_fsaverage164_atlas_gii="${temporary_dir}/atlases/fsaverage164.R.${atlas_name}.label.gii"
	if [ ! -f ${right_fsaverage164_atlas_gii} ]; then
		wb_command -label-resample "${right_atlas_gii}" "${right_fsLR32k_gii}" "${right_fsLR_to_fsaverage164}" BARYCENTRIC \
				   "${right_fsaverage164_atlas_gii}"
	fi

	echo -e "${GREEN}[INFO]`date`:${NC} Atlas resampled to fsaverage surface."

	# --------------------------------------------------------------------------------
	# Convert fsaverage atlas to annot format
	# --------------------------------------------------------------------------------

	# create symlink to fsaverage files
	if [ ! -e "${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/fsaverage164" ]; then
		ln -s "${fsaverage_dir}" "${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/fsaverage164"
	fi

	left_fsaverage164_sphere="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/fsaverage164/surf/lh.sphere"
	if [ ! -f ${left_fsaverage164_atlas_fs} ]; then
		# mris_convert --annot "${left_fsaverage164_atlas_gii}" "${left_fsaverage164_sphere}" "${left_fsaverage164_atlas_fs}"
		# the mris_convert script was replaced with a python script due to a bug in mris_convert
		python3 "${script_dir}/python/convert_labels_gii_to_annot.py" "${left_fsaverage164_atlas_gii}" "${left_fsaverage164_atlas_fs}"
	fi

	right_fsaverage164_sphere="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/fsaverage164/surf/rh.sphere"
	if [ ! -f ${right_fsaverage164_atlas_fs} ]; then
		# mris_convert --annot "${right_fsaverage164_atlas_gii}" "${right_fsaverage164_sphere}" "${right_fsaverage164_atlas_fs}"
		# the mris_convert script was replaced with a python script due to a bug in mris_convert
		python3 "${script_dir}/python/convert_labels_gii_to_annot.py" "${right_fsaverage164_atlas_gii}" "${right_fsaverage164_atlas_fs}"
	fi

	echo -e "${GREEN}[INFO]`date`:${NC} Labels (fsaverage) converted to .annot format."
fi

if [ "${atlas_space}" == "fsaverage" ]; then
	echo -e "${GREEN}[INFO]`date`:${NC} Starting to map fsaverage label to fsnative"

	# --------------------------------------------------------------------------------
	# Convert annot files to the appropriate format
	# --------------------------------------------------------------------------------
	left_fsaverage164_atlas_fs_source="${template_dir}/atlases/lh.${atlas_file}"
	right_fsaverage164_atlas_fs_source="${template_dir}/atlases/rh.${atlas_file}"

	if [ ! -f ${left_fsaverage164_atlas_fs} ] || [ ! -f ${right_fsaverage164_atlas_fs} ]; then
		python3 "${script_dir}/python/convert_schaefer_annot.py" ${left_fsaverage164_atlas_fs_source} \
		 		${right_fsaverage164_atlas_fs_source} ${left_fsaverage164_atlas_fs} ${right_fsaverage164_atlas_fs}
	fi
fi

# --------------------------------------------------------------------------------
# Resample fsaverage labels to native surfaces
# --------------------------------------------------------------------------------

if [ "${atlas_space}" == "fsLR" ] || [ "${atlas_space}" == "fsaverage" ]; then
	if [ ! -d "${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/atlases" ]; then
		mkdir -p "${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/atlases"
	fi

	export SUBJECTS_DIR="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}"

	# use mri_surf2surf to resample fsaverage to fsnative
	if [ ! -f ${left_native_atlas_fs} ]; then
		mri_surf2surf --srcsubject fsaverage164 --trgsubject FreeSurfer --hemi lh --sval-annot "${left_fsaverage164_atlas_fs}" \
					  --tval "${left_native_atlas_fs}"
	fi

	if [ ! -f ${right_native_atlas_fs} ]; then
		mri_surf2surf --srcsubject fsaverage164 --trgsubject FreeSurfer --hemi rh --sval-annot "${right_fsaverage164_atlas_fs}" \
					  --tval "${right_native_atlas_fs}"
	fi

	echo -e "${GREEN}[INFO]`date`:${NC} Native atlas constructed from fsaverage."
fi

if [ "${atlas_space}" == "native" ]; then
	echo -e "${GREEN}[INFO]`date`:${NC} Converting the native labels to a compatible format"

	# --------------------------------------------------------------------------------
	# Convert annot files to the appropriate format
	# --------------------------------------------------------------------------------
	left_native_atlas_fs_source="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/FreeSurfer/label/lh.${atlas_file}"
	right_native_atlas_fs_source="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/FreeSurfer/label/rh.${atlas_file}"

	if [ ! -f ${left_native_atlas_fs} ] || [ ! -f ${right_native_atlas_fs} ]; then
		python3 "${script_dir}/python/convert_native_annot.py" ${left_native_atlas_fs_source} \
		 		${right_native_atlas_fs_source} ${left_native_atlas_fs} ${right_native_atlas_fs}
	fi
fi

echo -e "${GREEN}[INFO]`date`:${NC} Surface label mapping finished.."
echo -e "${GREEN}[INFO]`date`:${NC} Check ${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/atlases for output."
