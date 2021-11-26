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
              -fslgrad "${dmri_dir}/bvecs" "${dmri_dir}/bvals" \
              -datatype float32 -strides 0,0,0,1
fi


# Estimate the response function using the dhollander method (~50sec)
##########################################################################################
# RS: As discussed, would be preferable to have used a group average response function,
# especially if the ODF images are to be provided to the community as that could result
# in wider applicability of those data for other projects (e.g. construction of multi-tissue
# odf template).
# This would not necessarily have to be an average across the *whole* UKB: you could obtain
# DWI data for some manageable subset and compute the average response functions from those,
# and those would be adequately representative to be used across all subjects.
##########################################################################################
wm_txt="${dmri_dir}/wm.txt"
gm_txt="${dmri_dir}/gm.txt"
csf_txt="${dmri_dir}/csf.txt"
if [ ! -f ${wm_txt} ] || [ ! -f ${gm_txt} ] || [ ! -f ${csf_txt} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Estimation of response function using dhollander"
    dwi2response dhollander "${dwi_mif}" "${wm_txt}" "${gm_txt}" "${csf_txt}" \
                            -voxels "${dmri_dir}/voxels.mif"
fi


# Multi-Shell, Multi-Tissue Constrained Spherical Deconvolution (~12min)
wm_fod="${dmri_dir}/wmfod.mif"
gm_fod="${dmri_dir}/gmfod.mif"
csf_fod="${dmri_dir}/csffod.mif"
dwi_mask="${dmri_dir}.bedpostX/nodif_brain_mask.nii.gz"
dwi_mask_dilated="${dmri_dir}.bedpostX/nodif_brain_mask_dilated_3.nii.gz"
if [ ! -f ${wm_fod} ] || [ ! -f ${gm_fod} ] || [ ! -f ${csf_fod} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running Multi-Shell, Multi-Tissue Constrained Spherical Deconvolution"
    
    # First, creating a dilated brain mask (https://github.com/sina-mansour/UKB-connectomics/issues/4)
    maskfilter -npass 3 "${dwi_mask}" dilate "${dwi_mask_dilated}"

    # Now, perfoming CSD with the dilated mask
    dwi2fod msmt_csd "${dwi_mif}" -mask "${dwi_mask_dilated}" \
                     "${wm_txt}" "${wm_fod}" "${gm_txt}" "${gm_fod}" "${csf_txt}" "${csf_fod}"
fi


# mtnormalise to perform multi-tissue log-domain intensity normalisation (~5sec)
wm_fod_norm="${dmri_dir}/wmfod_norm.mif"
gm_fod_norm="${dmri_dir}/gmfod_norm.mif"
csf_fod_norm="${dmri_dir}/csffod_norm.mif"
if [ ! -f ${wm_fod_norm} ] || [ ! -f ${gm_fod_norm} ] || [ ! -f ${csf_fod_norm} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running multi-tissue log-domain intensity normalisation"
    
    # First, creating an eroded brain mask (https://github.com/sina-mansour/UKB-connectomics/issues/5)
    maskfilter -npass 1 "${dwi_mask}" erode "${dmri_dir}.bedpostX/nodif_brain_mask_eroded_1.nii.gz"

    # Now, perfoming mtnormalise
    mtnormalise "${wm_fod}" "${wm_fod_norm}" "${gm_fod}" "${gm_fod_norm}" "${csf_fod}" \
                "${csf_fod_norm}" -mask "${dmri_dir}.bedpostX/nodif_brain_mask_eroded_1.nii.gz"
fi



# Create a mask of white matter gray matter interface using 5 tissue type segmentation (~30sec)
# Q:Shall we use FSL FAST's output or Freesurfer or the new hsvs? --> freesurfer is faster
#####################################################################################
# RS: 5ttgen freesurfer is probably the best choice given limited computational resources.
# I have recently come across a new FreeSurfer module:
# https://surfer.nmr.mgh.harvard.edu/fswiki/ScLimbic
# I have worked on integrating this into 5ttgen freesurfer. Tracking behaviour around this
# area is notoriously bad, so it would be good to clean up. Pretty sure the anterior
# commissure gets cut off completely without it (at least it does in HSVS). 
# https://github.com/MRtrix3/mrtrix3/issues/2390
# 
# Using -nocrop will result in a larger image, which will result in slightly inferior
# caching performance during tractography. If planning to distribute these data to the
# community, it may be preferable to use just so that the image dimensions are identical
# to the originating FreeSurfer images, but if you're hunting performance it would be
# better to omit this command-line option.
#
# I do not trust the FreeSurfer sub-cortical grey matter segmentations at all. Better would
# be to strip them out, then take the pre-existing FSL FIRST outputs and insert those
# segmentations into the 5TT image. The labelsgmfix script already does this for parcellation
# images; a similar approach could be used here for 5TT images. It would require a little
# development work on my part, but not a huge amount. I showed in the supplementary material
# of this article that connectome reproducibility can be improved simply by using the FIRST
# segmentations rather than the FreeSurfer ones:
# https://www.sciencedirect.com/science/article/pii/S1053811914008155#s0130
#####################################################################################
freesurfer_5tt_T1="${dmri_dir}/5tt.T1.freesurfer.mif"
freesurfer_5tt="${dmri_dir}/5tt.freesurfer.mif"
dwi_meanbzero="${dmri_dir}/dwi_meanbzero.mif"
T1_brain="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/T1/T1_brain.nii.gz"
T1_brain_dwi="${dmri_dir}/T1_brain_dwi.mif"
T1_brain_mask="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/T1/T1_brain_mask.nii.gz"
dwi_pseudoT1="${dmri_dir}/dwi_pseudoT1.mif"
T1_pseudobzero="${dmri_dir}/T1_pseudobzero.mif"
transform_pT1_T1="${dmri_dir}/transform_pT1_T1.txt"
transform_b0_pb0="${dmri_dir}/transform_b0_pb0.txt"
transform_DWI_T1="${dmri_dir}/transform_DWI_T1.txt"
gmwm_seed_T1="${dmri_dir}/gmwm_seed_T1.mif"
gmwm_seed="${dmri_dir}/gmwm_seed.mif"
if [ ! -f ${gmwm_seed} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running 5ttgen to get gray matter white matter interface mask"
    # First create the 5tt image
    5ttgen freesurfer "${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/FreeSurfer/mri/aparc+aseg.mgz" \
                      "${freesurfer_5tt_T1}" -nocrop -sgm_amyg_hipp

    # Next generate the boundary ribbon
    5tt2gmwmi "${freesurfer_5tt_T1}" "${gmwm_seed_T1}"

    # Coregistering the Diffusion and Anatomical Images
    # Check these links for further info:
    # https://github.com/sina-mansour/UKB-connectomics/issues/7
    # https://github.com/BIDS-Apps/MRtrix3_connectome/blob/0.5.0/mrtrix3_connectome.py#L1625-L1707
    # https://andysbrainbook.readthedocs.io/en/latest/MRtrix/MRtrix_Course/MRtrix_06_TissueBoundary.html
    # T1 and dMRI images are in different spaces, hence we'll use a rigid body transformation.

    # Generate contrast matched target images for coregistration
    dwiextract "${dwi_mif}" -bzero - | mrcalc - 0.0 -max - | mrmath - mean -axis 3 "${dwi_meanbzero}"
    mrcalc 1 "${dwi_meanbzero}" -div "${dwi_mask}" -mult - | mrhistmatch nonlinear - "${T1_brain}" \
           "${dwi_pseudoT1}" -mask_input "${dwi_mask}" -mask_target "${T1_brain_mask}"
    mrcalc 1 "${T1_brain}" -div "${T1_brain_mask}" -mult - | mrhistmatch nonlinear - "${dwi_meanbzero}" \
           "${T1_pseudobzero}" -mask_input "${T1_brain_mask}" -mask_target "${dwi_mask}"

    # Perform rigid body registration
    mrregister "${dwi_pseudoT1}" "${T1_brain}" -type rigid -mask1 "${dwi_mask}" -mask2 "${T1_brain_mask}" \
               -rigid "${transform_pT1_T1}"
    mrregister "${dwi_meanbzero}" "${T1_pseudobzero}" -type rigid -mask1 "${dwi_mask}" -mask2 "${T1_brain_mask}" \
               -rigid "${transform_b0_pb0}"
    transformcalc "${transform_pT1_T1}" "${transform_b0_pb0}" average "${transform_DWI_T1}"

    # Perform transformation of the boundary ribbon from T1 to DWI space
    mrtransform "${T1_brain}" "${T1_brain_dwi}" -linear "${transform_DWI_T1}" -inverse
    mrtransform "${freesurfer_5tt_T1}" "${freesurfer_5tt}" -linear "${transform_DWI_T1}" -inverse
    mrtransform "${gmwm_seed_T1}" "${gmwm_seed}" -linear "${transform_DWI_T1}" -inverse
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
#############################################################################################
# RS: 
# - Default FOD amplitude cutoff is a compromise knowing that users could be providing either
#   single-tissue or multi-tissue WM ODFs. Given the use of multi-tissue CSD here, as well as
#   the use of ACT (or comparable masks), probably safe to reduce this to 0.05
#   (note that if ACT is used, the default FOD cutoff is automatically cut in half, in which
#   case there would be no need to use the command-line option)
# - The output of 5tt2gmwmi is generally intended to be used in conjunction with -seed_gmwmi.
#   Providing that image via -seed_image will result in a large proportion of candidate seeds
#   being rejected due to being in cortical GM in the case of ACT or outside of the mask image
#   in the case of not using ACT. You should see if using -seed_gmwmi that the discrepancy between
#   seed count and streamline count should decrease.
# - If quantification of Fibre Bundle Capacity (FBC) is a priority, then I would usually
#   advocate the use of -seed_dynamic. This would however incur the cost of FOD segmentation
#   (which is additionally performed within SIFT(2); preferable would be to do that segmentation
#   once and then load those pre-computed results in both instances), and it would potentially
#   confound the interpretation of raw streamline count measures (there is some sense of known
#   biases present in such for both homogeneous WM and GM-WM interface seeding, whereas for
#   dynamic seeding the raw streamline count becomes slightly more comparable to FBC).
# - -nthreads 1 will actually result in the use of 2 threads here: there is one dedicated thread
#   for writing to the track file, and you are requesting one worker thread for doing the tracking
#   itself. If you genuinely do not want the command to spawn any threads at all, use -nthreads 0.
#   (This will also remove the need for locking as generated streamline data are passed from one
#   thread to another)
# - -trials isn't something that would typically be modified
# - The other option to consider is -power. One of the reasons why iFOD2 remains unpublished is
#   because we still don't have a robust answer for what this should be. But over and above that,
#   even within the logic that was used to derive the current default value, there is still an
#   error. The default is (1 / samples), whereas it should actually be (1 / (samples-1)).
#   I would suggest running with -power 0.333333 and see if it changes execution speed substantially;
#   it will slightly reduce the magnitude of the probabilistic "wiggle".
# - In addition to testing execution speed between iFOD1 and iFOD2, you could also try iFOD2 with
#   -samples 3 (and possibly also then with -power 0.5 as per point above), and see the extent to
#   which that improves execution speed.
# - Ideally I would like to have this algorithm:
#   https://github.com/MRtrix3/mrtrix3/issues/2160
#   However I do believe that it runs slower than iFOD2.
#   I'm not sure that I'll be able to find the time to implement it, but it's a great little
#   project for e.g. a Masters internship in CompSci.
# - For now, run with -info to get additional statistics on tractography outcomes (and this will be
#   further augmented if ACT is used). In the future, rather than attempting to parse the stderr
#   output here, I could add a command-line option to tckgen that would write these statistics
#   to a file for easier access.
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
           -maxlength 250 -cutoff 0.1 -nthreads 0 "${wm_fod_norm}" "${tracks}" -power 0.5 \
           -info -samples 3
fi

# Tractography considerations:
# IFOD1 vs. IFOD2
# It might be better to use -seeds
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
