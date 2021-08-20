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
atlas_name=$4
atlas_file=$5

template_dir="${main_dir}/data/templates"
temporary_dir="${main_dir}/data/temporary"

fsaverage_dir="${template_dir}/freesurfer/fsaverage"

echo -e "${GREEN}[INFO]`date`:${NC} Atlas: ${atlas_name}"
echo -e "${GREEN}[INFO]`date`:${NC} Located at: ${atlas_file}"
echo -e "${GREEN}[INFO]`date`:${NC} Starting to map fsLR label to fsnative"

# --------------------------------------------------------------------------------
# Convert glasser label files to label.gii format
# --------------------------------------------------------------------------------

atlas_label="${template_dir}/atlases/${atlas_file}"

if [ ! -d "${temporary_dir}/templates/atlases" ]; then
	mkdir -p "${temporary_dir}/templates/atlases"
fi

left_atlas_gii="${temporary_dir}/templates/atlases/${atlas_name}.L.32k_fs_LR.label.gii"
if [ ! -f ${left_atlas_gii} ]; then
	wb_command -cifti-separate "${atlas_label}" COLUMN -label CORTEX_LEFT "${left_atlas_gii}"
fi

right_atlas_gii="${temporary_dir}/templates/atlases/${atlas_name}.R.32k_fs_LR.label.gii"
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
	wb_command -label-resample "${left_atlas_gii}" "${left_fsLR32k_gii}" "${left_fsLR_to_fsaverage164}" BARYCENTRIC "${left_fsaverage164_atlas_gii}"
fi

right_fsaverage164_atlas_gii="${temporary_dir}/atlases/fsaverage164.R.${atlas_name}.label.gii"
if [ ! -f ${right_fsaverage164_atlas_gii} ]; then
	wb_command -label-resample "${right_atlas_gii}" "${right_fsLR32k_gii}" "${right_fsLR_to_fsaverage164}" BARYCENTRIC "${right_fsaverage164_atlas_gii}"
fi

echo -e "${GREEN}[INFO]`date`:${NC} Atlas resampled to fsaverage surface."

# --------------------------------------------------------------------------------
# Convert fsaverage atlas to annot format
# --------------------------------------------------------------------------------

left_fsaverage164_atlas_fs="${temporary_dir}/atlases/lh.fsaverage164.${atlas_name}.annot"
if [ ! -f ${left_fsaverage164_atlas_fs} ]; then
	mris_convert --annot "${left_fsaverage164_atlas_gii}" "${left_fsLR_to_fsaverage164}" "${left_fsaverage164_atlas_fs}"
fi

right_fsaverage164_atlas_fs="${temporary_dir}/atlases/rh.fsaverage164.${atlas_name}.annot"
if [ ! -f ${right_fsaverage164_atlas_fs} ]; then
	mris_convert --annot "${right_fsaverage164_atlas_gii}" "${right_fsLR_to_fsaverage164}" "${right_fsaverage164_atlas_fs}"
fi

echo -e "${GREEN}[INFO]`date`:${NC} Labels (fsaverage) converted to .annot format."

# --------------------------------------------------------------------------------
# Resample fsaverage labels to native surfaces
# --------------------------------------------------------------------------------

if [ ! -d "${temporary_dir}/subjects/${ukb_subject_id}/atlases" ]; then
	mkdir -p "${temporary_dir}/subjects/${ukb_subject_id}/atlases"
fi

# create symlink to fsaverage files
if [ ! -e "${ukb_subjects_dir}/${ukb_subject_id}/fsaverage164" ]; then
	ln -s "${fsaverage_dir}" "${ukb_subjects_dir}/${ukb_subject_id}/fsaverage164"
fi

export SUBJECTS_DIR="${ukb_subjects_dir}/${ukb_subject_id}"

# use mri_surf2surf to resample fsaverage to fsnative
left_native_atlas_fs="${temporary_dir}/subjects/${ukb_subject_id}/atlases/lh.native.${atlas_name}.annot"
if [ ! -f ${left_native_atlas_fs} ]; then
	mri_surf2surf --srcsubject fsaverage164 --trgsubject FreeSurfer --hemi lh --sval-annot "${left_fsaverage164_atlas_fs}" --tval "${left_native_atlas_fs}"
fi

right_native_atlas_fs="${temporary_dir}/subjects/${ukb_subject_id}/atlases/rh.native.${atlas_name}.annot"
if [ ! -f ${right_native_atlas_fs} ]; then
	mri_surf2surf --srcsubject fsaverage164 --trgsubject FreeSurfer --hemi rh --sval-annot "${right_fsaverage164_atlas_fs}" --tval "${right_native_atlas_fs}"
fi

echo -e "${GREEN}[INFO]`date`:${NC} Native atlas constructed from fsaverage."
echo -e "${GREEN}[INFO]`date`:${NC} Check ${temporary_dir}/subjects/${ukb_subject_id}/atlases for output."
echo -e "${GREEN}[INFO]`date`:${NC} Surface label mapping (fsLR to fsnative) finished.."
