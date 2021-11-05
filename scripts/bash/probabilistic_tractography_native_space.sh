#!/bin/bash

# This script is be used to estimate probabilistic tractography streamlines.
# It mainly uses codes from MRtrix 3.0 (https://www.mrtrix.org/)
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
# modify this to refere to where the subject data is stored at
# the ralative maps may need to be redefined to apply to UKB directory structure

main_dir=$1
ukb_subjects_dir=$2
ukb_subject_id=$3
ukb_instance=$4

script_dir="${main_dir}/scripts"
template_dir="${main_dir}/data/templates"
temporary_dir="${main_dir}/data/temporary"

fsaverage_dir="${template_dir}/freesurfer/fsaverage"
dmri_dir="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/dMRI/dMRI"

echo -e "${GREEN}[INFO]`date`:${NC} Starting tractography for: ${ukb_subject_id}_${ukb_instance}"

# Create a temporary directory to store files
tractography_dir="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography"
if [ ! -d "${tractography_dir}" ]; then
    mkdir -p "${tractography_dir}"
fi

# First convert the initial diffusion image to .mif (~10sec)
dwi_mif="${dmri_dir}/dwi.mif"
if [ ! -f ${dwi_mif} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Converting dwi image to mif"
    mrconvert "${dmri_dir}/data_ud.nii.gz" "${dwi_mif}" \
              -fslgrad "${dmri_dir}/bvecs" "${dmri_dir}/bvals" \
              -datatype float32 -strides 0,0,0,1
fi


# Estimate the response function using the dhollander method (~50sec)
wm_txt="${dmri_dir}/wm.txt"
gm_txt="${dmri_dir}/gm.txt"
csf_txt="${dmri_dir}/csf.txt"
if [ ! -f ${wm_txt} ] || [ ! -f ${gm_txt} ] || [ ! -f ${csf_txt} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Estimation of response function using dhollander"
    dwi2response dhollander "${dwi_mif}" "${wm_txt}" "${gm_txt}" "${csf_txt}" \
                            -voxels "${dmri_dir}/voxels.mif"
fi


# Multi-Shell, Multi-Tissue Constrained Spherical Deconvolution (~8min)
wm_fod="${dmri_dir}/wmfod.mif"
gm_fod="${dmri_dir}/gmfod.mif"
csf_fod="${dmri_dir}/csffod.mif"
if [ ! -f ${wm_fod} ] || [ ! -f ${gm_fod} ] || [ ! -f ${csf_fod} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running Multi-Shell, Multi-Tissue Constrained Spherical Deconvolution"
    dwi2fod msmt_csd "${dwi_mif}" -mask "${dmri_dir}.bedpostX/nodif_brain_mask.nii.gz" \
                     "${wm_txt}" "${wm_fod}" "${gm_txt}" "${gm_fod}" "${csf_txt}" "${csf_fod}"
fi

# Create a mask of white matter gray matter interface using 5 tissue type segmentation (~10sec)
# Q:Shall we use FSL FAST's output or Freesurfer or the new hsvs? --> freesurfer is faster
freesurfer_5tt="${dmri_dir}/5tt.freesurfer.mif"
gmwm_seed="${dmri_dir}/gmwm_seed.mif"
if [ ! -f ${gmwm_seed} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running 5ttgen to get gray matter white matter interface mask"
    # First create the 5tt image
    5ttgen freesurfer "${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/FreeSurfer/mri/aparc+aseg.mgz" \
                      "${freesurfer_5tt}" -nocrop -sgm_amyg_hipp

    # Coregistering the Diffusion and Anatomical Images
    # https://andysbrainbook.readthedocs.io/en/latest/MRtrix/MRtrix_Course/MRtrix_06_TissueBoundary.html
    # Not needed, as T1 and dMRI images are in the same space.

    # Next generate the boundary ribbon
    5tt2gmwmi "${freesurfer_5tt}" "${gmwm_seed}"
fi

# Create white matter + subcortical binary mask to trim streamline endings (~1sec)
trim_mask="${dmri_dir}/trim.mif"
if [ ! -f ${trim_mask} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running code to generate trimming mask"
    # first extract the white matter and subcortical tissues from 5tt image
    mrconvert --coord 3 2 -axes 0,1,2 "${freesurfer_5tt}" "${dmri_dir}/5tt-white_matter.mif"
    mrconvert --coord 3 1 -axes 0,1,2 "${freesurfer_5tt}" "${dmri_dir}/5tt-subcortical.mif"
    # add tissues together
    mrmath "${dmri_dir}/5tt-white_matter.mif" "${dmri_dir}/5tt-subcortical.mif" \
           sum "${dmri_dir}/5tt-wm+sc.mif"
    # binarise to create the trim mask
    mrcalc "${dmri_dir}/5tt-wm+sc.mif" 0 -gt 1 0 -if "${trim_mask}"
fi


# Create streamlines
# - 1 million streams are seeded using -seeds
# - no ACT
# - maxlength is set to 250mm as the default option results in streamlines
#   being at most 100 * voxelsize which will be 200mm and may result in loss
#   of long streamlines for UKB data resolution
# - FOD amplitude cutoff is set to 0.1 (shal be discussed)
# - trim mask is used to crop streamline endpoints more precisely as they
#   cross white matter - cortical gray matter interface
# - not using multiple threads to speed-up (as it might cause lesser jobs accepted in the queue)
streamlines="100K" # testing with a smaller value: for 100K seeds, it took ~40sec, see below:
# tckgen: [100%]   100000 seeds,    44305 streamlines,    17317 selected
tracks="${dmri_dir}/tracks_${streamlines}.tck"
if [ ! -f ${tracks} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running probabilistic tractography"
    tckgen -seed_image "${gmwm_seed}" -mask "${trim_mask}" -seeds "${streamlines}" \
           -maxlength 250 -cutoff 0.1 -nthreads 1 "${wm_fod}" "${tracks}"
           # extra options to check??? -act -crop_at_gmwmi -seed_gmwmi -trials -step -seeds
fi

# Tractography considerations:
# IFOD1 vs. IFOD2
# It might be better to use -seeds
# Mean FA, MD, tensor eigenvecs, length, mean 5tt, diffusion kurtosis fit, freewater,


echo -e "${GREEN}[INFO]`date`:${NC} Finished tractography for: ${ukb_subject_id}_${ukb_instance}"

