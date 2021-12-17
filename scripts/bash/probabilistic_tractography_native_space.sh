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

mrtrix_dir="${main_dir}/lib/mrtrix3/bin"
script_dir="${main_dir}/scripts"
template_dir="${main_dir}/data/templates"
temporary_dir="${main_dir}/data/temporary"

fsaverage_dir="${template_dir}/freesurfer/fsaverage"
dmri_dir="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/dMRI/dMRI"

threading="-nthreads 0"

echo -e "${GREEN}[INFO]${NC} `date`: Starting tractography for: ${ukb_subject_id}_${ukb_instance}"

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
              -fslgrad "${dmri_dir}/data.eddy_rotated_bvecs" "${dmri_dir}/bvals" \
              -datatype float32 -strides 0,0,0,1 ${threading} -info
fi

# Then, extract mean B0 image (~1sec)
dwi_meanbzero="${dmri_dir}/dwi_meanbzero.mif"
dwi_meanbzero_nii="${dmri_dir}/dwi_meanbzero.nii.gz"
if [ ! -f ${dwi_meanbzero} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Extracting mean B0 image"

    # extract mean b0
    dwiextract ${threading} -info "${dwi_mif}" -bzero - | mrmath ${threading} -info - mean -axis 3 "${dwi_meanbzero}"
    mrconvert "${dwi_meanbzero}" "${dwi_meanbzero_nii}" ${threading} -info
fi

# Then, create a dwi brain mask (the provided bedpostX mask is not that accurate) (~2sec)
dwi_meanbzero_brain="${dmri_dir}/dwi_meanbzero_brain.nii.gz"
dwi_meanbzero_brain_mask="${dmri_dir}/dwi_meanbzero_brain_mask.nii.gz"
if [ ! -f ${dwi_meanbzero_brain_mask} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Computing dwi brain mask"

    # Approach 2: using FSL BET (check https://github.com/sina-mansour/UKB-connectomics/commit/463b6553b5acd63f14a45ef7120145998e0a5139)

    # skull stripping to get a mask
    bet "${dwi_meanbzero_nii}" "${dwi_meanbzero_brain}" -m -R -f 0.2 -g -0.05
fi


# Estimate the response function using the dhollander method (~4min)
wm_txt="${dmri_dir}/wm.txt"
gm_txt="${dmri_dir}/gm.txt"
csf_txt="${dmri_dir}/csf.txt"
if [ ! -f ${wm_txt} ] || [ ! -f ${gm_txt} ] || [ ! -f ${csf_txt} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Estimation of response function using dhollander"
    dwi2response dhollander "${dwi_mif}" "${wm_txt}" "${gm_txt}" "${csf_txt}" \
                            -voxels "${dmri_dir}/voxels.mif" ${threading} -info
fi


# Multi-Shell, Multi-Tissue Constrained Spherical Deconvolution (~33min)
wm_fod="${dmri_dir}/wmfod.mif"
gm_fod="${dmri_dir}/gmfod.mif"
csf_fod="${dmri_dir}/csffod.mif"
dwi_mask_dilated="${dmri_dir}/dwi_meanbzero_brain_mask_dilated_2.nii.gz"
if [ ! -f ${wm_fod} ] || [ ! -f ${gm_fod} ] || [ ! -f ${csf_fod} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running Multi-Shell, Multi-Tissue Constrained Spherical Deconvolution"
    
    # First, creating a dilated brain mask (https://github.com/sina-mansour/UKB-connectomics/issues/4)
    maskfilter -npass 2 "${dwi_meanbzero_brain_mask}" dilate "${dwi_mask_dilated}" ${threading} -info

    # Now, perfoming CSD with the dilated mask
    dwi2fod msmt_csd "${dwi_mif}" -mask "${dwi_mask_dilated}" "${wm_txt}" "${wm_fod}" \
            "${gm_txt}" "${gm_fod}" "${csf_txt}" "${csf_fod}" ${threading} -info
fi


# mtnormalise to perform multi-tissue log-domain intensity normalisation (~5sec)
wm_fod_norm="${dmri_dir}/wmfod_norm.mif"
gm_fod_norm="${dmri_dir}/gmfod_norm.mif"
csf_fod_norm="${dmri_dir}/csffod_norm.mif"
if [ ! -f ${wm_fod_norm} ] || [ ! -f ${gm_fod_norm} ] || [ ! -f ${csf_fod_norm} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running multi-tissue log-domain intensity normalisation"
    
    # First, creating an eroded brain mask (https://github.com/sina-mansour/UKB-connectomics/issues/5)
    maskfilter -npass 2 "${dwi_meanbzero_brain_mask}" erode "${dmri_dir}/dwi_meanbzero_brain_mask_eroded_2.nii.gz" ${threading} -info

    # Now, perfoming mtnormalise
    mtnormalise "${wm_fod}" "${wm_fod_norm}" "${gm_fod}" "${gm_fod_norm}" "${csf_fod}" \
                "${csf_fod_norm}" -mask "${dmri_dir}/dwi_meanbzero_brain_mask_eroded_2.nii.gz" ${threading} -info
fi


# Create a mask of white matter gray matter interface using 5 tissue type segmentation (~70sec)
freesurfer_5tt_T1="${dmri_dir}/5tt.T1.freesurfer.mif"
freesurfer_5tt="${dmri_dir}/5tt.freesurfer.mif"
T1_brain="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/T1/T1_brain.nii.gz"
T1_first="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/T1/T1_first/"
T1_brain_dwi="${dmri_dir}/T1_brain_dwi.mif"
T1_brain_mask="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/T1/T1_brain_mask.nii.gz"
gmwm_seed_T1="${dmri_dir}/gmwm_seed_T1.mif"
gmwm_seed="${dmri_dir}/gmwm_seed.mif"
transform_DWI_T1_FSL="${dmri_dir}/diff2struct_fsl.txt"
transform_DWI_T1="${dmri_dir}/diff2struct_mrtrix.txt"
if [ ! -f ${gmwm_seed} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running 5ttgen to get gray matter white matter interface mask"
    # First create the 5tt image
    ${mrtrix_dir}/5ttgen freesurfer "${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/FreeSurfer/mri/aparc+aseg.mgz" \
                         -first ${T1_first} "${freesurfer_5tt_T1}" \
                         -nocrop -sgm_amyg_hipp ${threading} -info

    # Next generate the boundary ribbon
    5tt2gmwmi "${freesurfer_5tt_T1}" "${gmwm_seed_T1}" ${threading} -info

    # Coregistering the Diffusion and Anatomical Images
    # Check these links for further info:
    # https://github.com/sina-mansour/UKB-connectomics/issues/7
    # https://github.com/BIDS-Apps/MRtrix3_connectome/blob/0.5.0/mrtrix3_connectome.py#L1625-L1707
    # https://andysbrainbook.readthedocs.io/en/latest/MRtrix/MRtrix_Course/MRtrix_06_TissueBoundary.html
    # https://community.mrtrix.org/t/aligning-dwi-to-t1-using-flirt/2388
    # https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FLIRT
    # T1 and dMRI images are in different spaces, hence we'll use a rigid body transformation.

    # Perform rigid body registration
    flirt -in "${dwi_meanbzero_brain}" -ref "${T1_brain}" \
          -cost normmi -dof 6 -omat "${transform_DWI_T1_FSL}"
    transformconvert "${transform_DWI_T1_FSL}" "${dwi_meanbzero_brain}" \
                     "${T1_brain}" flirt_import "${transform_DWI_T1}"

    # Perform transformation of the boundary ribbon from T1 to DWI space
    mrtransform "${freesurfer_5tt_T1}" "${freesurfer_5tt}" -linear "${transform_DWI_T1}" -inverse ${threading} -info
    mrtransform "${T1_brain}" "${T1_brain_dwi}" -linear "${transform_DWI_T1}" -inverse ${threading} -info
    mrtransform "${gmwm_seed_T1}" "${gmwm_seed}" -linear "${transform_DWI_T1}" -inverse ${threading} -info
fi


# Create streamlines
# - maxlength is set to 250mm as the default option results in streamlines
#   being at most 100 * voxelsize which will be 200mm and may result in loss
#   of long streamlines for UKB data resolution
# - not using multiple threads to speed-up (as it might cause lesser jobs accepted in the queue)
#############################################################################################
# RS: 
# - In addition to testing execution speed between iFOD1 and iFOD2, you could also try iFOD2 with
#   -samples 3 (and possibly also then with -power 0.5 as per point above), and see the extent to
#   which that improves execution speed.
# - Theoretically, you could do a combination of GM-WM interface seeding and homogeneous WM seeding.
#   You could then have connectomes with half the streamline count using data from each individually,
#   and connectomes using the concatenation of the two tractograms, which would potentially somewhat
#   mitigate the biases present in each. FBC quantification would use the concatenation of the two.
#   But this may be exposing a feature of the reconstruction pipeline that we explicitly *don't want*
#   to explore?
# - Still discussion to be had RE: requesting specific number of seeds vs. streamlines vs. selected streamlines
#   https://github.com/MRtrix3/mrtrix3/issues/2391
#############################################################################################
streamlines="100K" # testing with a smaller value: for 100K seeds, it took ~70sec, see below:
# tckgen: [100%]   100000 seeds,    44305 streamlines,    17317 selected
tracks="${dmri_dir}/tracks_${streamlines}.tck"
if [ ! -f ${tracks} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running probabilistic tractography"
    tckgen -seed_gmwmi "${gmwm_seed}" -act "${freesurfer_5tt}" -seeds "${streamlines}" \
           -maxlength 250 -cutoff 0.1 ${threading} "${wm_fod_norm}" "${tracks}" -power 0.5 \
           -info -samples 3
fi

# computing SIFT2 weightings (~150sec for 100K, however may not scale linearly needs to be tested on more streamlines)
sift_weights="${dmri_dir}/sift_weights.txt"
if [ ! -f ${sift_weights} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running SIFT2"
    tcksift2 ${threading} -info "${tracks}" "${wm_fod_norm}" "${sift_weights}"
fi

# Tractography considerations:
# IFOD1 vs. IFOD2
# Mean FA, MD, tensor eigenvecs, length, mean 5tt, diffusion kurtosis fit, freewater,


###############################################################################################
# RS:
# - We had discussed the prospect of modifying the tcksample command to derive, for each
#   streamline trajectory, samples from multiple quantitative 3D images, so that tcksample would
#   not need to be executed once per quantitative measure, which could be slow due simply to 
#   having to read through the track file once per quantitative measure.
# - One I did not think of at the time is that we could theoretically do the same approach as
#   above, but for connectome construction. tck2connectome could receive as input a 4D image, where
#   each volume of the series is a unique hard parcellation, and the command would generate in
#   a single invocation one connectome per volume. This would however require a decent amount of
#   work on my part, so we'd need to see how many parcellations you want to use and how long
#   tck2connectome takes per execution to know whether or not this is worthwhile.
# - As per a prior point above: if the tractogram were stored on a RAM filesystem rather than
#   on a network file share, then the time spent loading streamlines data in both tcksample and
#   tck2connectome would be much shorter.
# - Potential additional connectivity metrics:
#   - Properties of multi-tissue decomposition (e.g. isometric log-ratios)
#   - Pre-calculated NODDI parameters
#   - FOD amplitude (existing code can only do exact FOD amplitude at streamline tangent;
#     code for sampling AFD as the integral of the FOD lobe is part of a very large changeset that
#     I started ~ 8 years ago; if it's considered highly desirable I can try to get it into a
#     working state)
#   - Note that pre-calculated tensors in UKB (presumably via FSL) will differ to those
#     calculated by MRtrix3's dwi2tensor. Ours uses a thoroughly-evaluated iterative reweighting
#     strategy (see references in command help page). So worth contemplating whether to use the
#     existing pre-calculated tensors, or re-calculate using MRtrix3.
# - Note also that for each quantitative metric, taking the *mean* value along the streamline
#   trajectory and attributing that single scalar value to the streamline is the typical solution,
#   but it's not a unique solution; one can also take e.g. the minimum value along the streamline
#   trajectory (see tcksample -stat_tck option). Many combinations of voxel-wise quantitative metric
#   and streamline-wise statistic will not make sense; but it's nevertheless worth considering the
#   whole space of possibilities.
###############################################################################################


echo -e "${GREEN}[INFO]${NC} `date`: Finished tractography for: ${ukb_subject_id}_${ukb_instance}"


################################################################################################
# RS: As per discussion, need to find out how much data can be uploaded per subject to UKB
# (and indeed what volume of data could potentially be hosted elsewhere). Any temporaries that
# are not to be later hosted anywhere are better off being stored on a RAM file system.
# My typical approach here is to load all input data into a scratch directory that I can force
# to be in /tmp/, store all intermediate files and final outputs there, and only upon script
# completion do I then write the desired derivatives to the location requested by the user.
# I then only retain the scratch directory if the user explicitly requests that it be retained.
# Your structure here checks for the pre-existence of calculated files, which is useful when you
# are testing perturbations to the script, but for final deployment this ability is not as high
# a priority.
################################################################################################
