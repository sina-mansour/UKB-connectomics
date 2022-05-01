#!/bin/bash

# This script is used to estimate probabilistic tractography streamlines.
# It mainly uses codes from MRtrix 3.0
# 
# Helpful resources:
# https://www.mrtrix.org/
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
streamlines=$5

mrtrix_dir="${main_dir}/lib/mrtrix3/bin"
script_dir="${main_dir}/scripts"
template_dir="${main_dir}/data/templates"
temporary_dir="${main_dir}/data/temporary"

fsaverage_dir="${template_dir}/freesurfer/fsaverage"
dmri_dir="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/dMRI/dMRI"

threading="-nthreads 0"

echo -e "${GREEN}[INFO]${NC} `date`: Starting tractography for: ${ukb_subject_id}_${ukb_instance}"

cd "${dmri_dir}"

# Create a temporary directory to store files
tractography_dir="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography"
if [ ! -d "${tractography_dir}" ]; then
    mkdir -p "${tractography_dir}"
fi

# First convert the initial diffusion image to .mif (~10sec)
dwi_mif="${dmri_dir}/dwi.mif"
if [ ! -f ${dwi_mif} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Converting dwi image to mif"
    # check for eddy rotated bvecs
    ${mrtrix_dir}/mrconvert "${dmri_dir}/data_ud.nii.gz" "${dwi_mif}" \
              -fslgrad "${dmri_dir}/bvecs" "${dmri_dir}/bvals" \
              -datatype float32 -strides 0,0,0,1 ${threading} -info
fi

# Then, extract mean B0 image (~1sec)
dwi_meanbzero="${dmri_dir}/dwi_meanbzero.mif"
dwi_meanbzero_nii="${dmri_dir}/dwi_meanbzero.nii.gz"
if [ ! -f ${dwi_meanbzero} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Extracting mean B0 image"

    # extract mean b0
    ${mrtrix_dir}/dwiextract ${threading} -info "${dwi_mif}" -bzero - | mrmath ${threading} -info - mean -axis 3 "${dwi_meanbzero}"
    ${mrtrix_dir}/mrconvert "${dwi_meanbzero}" "${dwi_meanbzero_nii}" ${threading} -info
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
    ${mrtrix_dir}/dwi2response dhollander "${dwi_mif}" "${wm_txt}" "${gm_txt}" "${csf_txt}" \
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
    ${mrtrix_dir}/maskfilter -npass 2 "${dwi_meanbzero_brain_mask}" dilate "${dwi_mask_dilated}" ${threading} -info

    # Now, perfoming CSD with the dilated mask
    ${mrtrix_dir}/dwi2fod msmt_csd "${dwi_mif}" -mask "${dwi_mask_dilated}" "${wm_txt}" "${wm_fod}" \
            "${gm_txt}" "${gm_fod}" "${csf_txt}" "${csf_fod}" ${threading} -info
fi


# mtnormalise to perform multi-tissue log-domain intensity normalisation (~5sec)
wm_fod_norm="${dmri_dir}/wmfod_norm.mif"
gm_fod_norm="${dmri_dir}/gmfod_norm.mif"
csf_fod_norm="${dmri_dir}/csffod_norm.mif"
if [ ! -f ${wm_fod_norm} ] || [ ! -f ${gm_fod_norm} ] || [ ! -f ${csf_fod_norm} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running multi-tissue log-domain intensity normalisation"
    
    # First, creating an eroded brain mask (https://github.com/sina-mansour/UKB-connectomics/issues/5)
    ${mrtrix_dir}/maskfilter -npass 2 "${dwi_meanbzero_brain_mask}" erode "${dmri_dir}/dwi_meanbzero_brain_mask_eroded_2.nii.gz" ${threading} -info

    # Now, perfoming mtnormalise
    ${mrtrix_dir}/mtnormalise "${wm_fod}" "${wm_fod_norm}" "${gm_fod}" "${gm_fod_norm}" "${csf_fod}" \
                "${csf_fod_norm}" -mask "${dmri_dir}/dwi_meanbzero_brain_mask_eroded_2.nii.gz" ${threading} -info
fi

# create a combined fod image for visualization
vf_mif="${dmri_dir}/vf.mif"
if [ ! -f ${vf_mif} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Generating a visualization file from normalized FODs"
    ${mrtrix_dir}/mrconvert ${threading} -info -coord 3 0 "${wm_fod_norm}" - | mrcat "${csf_fod_norm}" "${gm_fod_norm}" - "${vf_mif}"
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
    ${mrtrix_dir}/5tt2gmwmi "${freesurfer_5tt_T1}" "${gmwm_seed_T1}" ${threading} -info

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
    ${mrtrix_dir}/transformconvert "${transform_DWI_T1_FSL}" "${dwi_meanbzero_brain}" \
                     "${T1_brain}" flirt_import "${transform_DWI_T1}"

    # Perform transformation of the boundary ribbon from T1 to DWI space
    ${mrtrix_dir}/mrtransform "${freesurfer_5tt_T1}" "${freesurfer_5tt}" -linear "${transform_DWI_T1}" -inverse ${threading} -info
    ${mrtrix_dir}/mrtransform "${T1_brain}" "${T1_brain_dwi}" -linear "${transform_DWI_T1}" -inverse ${threading} -info
    ${mrtrix_dir}/mrtransform "${gmwm_seed_T1}" "${gmwm_seed}" -linear "${transform_DWI_T1}" -inverse ${threading} -info
fi


# Create streamlines
# - maxlength is set to 250mm as the default option results in streamlines
#   being at most 100 * voxelsize which will be 200mm and may result in loss
#   of long streamlines for UKB data resolution
# - not using multiple threads to speed-up (as it might cause fewer jobs being
#   accepted in the queue)
# testing with a smaller value: for 100K seeds, it took ~70sec, see below:
# tckgen: [100%]   100000 seeds,    44305 streamlines,    17317 selected
tracks="${dmri_dir}/tracks_${streamlines}.tck"
trackstats="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/stats/tracks_${streamlines}_stats.json"
mkdir -p "${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/stats"
if [ ! -f ${tracks} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running probabilistic tractography"
    ${mrtrix_dir}/tckgen -seed_gmwmi "${gmwm_seed}" -act "${freesurfer_5tt}" -seeds "${streamlines}" \
                         -maxlength 250 -cutoff 0.1 ${threading} "${wm_fod_norm}" "${tracks}" -power 0.5 \
                         -info -samples 3 -select 0 -output_stats "${trackstats}"
fi


# resample endpoints
endpoints="${dmri_dir}/tracks_${streamlines}_endpoints.tck"
if [ ! -f ${endpoints} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Resampling streamline endpoints"
    ${mrtrix_dir}/tckresample ${threading} -info -endpoints "${tracks}" "${endpoints}"
fi

# extract other weightings (than raw streamline count)

# computing SIFT2 weightings (~4min for 10M seeds)
downsampled_wm_fod_norm="${dmri_dir}/downsampled_wmfod_norm.mif"
sift_weights_npy="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/sift_weights.npy"
sift_stats="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/stats/sift_stats.csv"
mkdir -p "${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics"
mkdir -p "${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/stats"
if [ ! -f ${sift_weights_npy} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Running SIFT2"
    # Optional: downsampling fod to save time and storage
    # check this thread:
    # https://mrtrix.readthedocs.io/en/3.0_rc3/troubleshooting/performance_and_crashes.html#commands-crashing-due-to-memory-requirements
    # additionally mrresize was changed to mrgrid, see below
    # https://community.mrtrix.org/t/mrresize/3589
    # ${mrtrix_dir}/mrgrid ${threading} -scale 0.5 "${wm_fod_norm}" regrid "${downsampled_wm_fod_norm}"
    # ${mrtrix_dir}/tcksift2 ${threading} -info "${tracks}" -act "${freesurfer_5tt}" -config NPYFloatMaxSavePrecision 16 \
    #                        -csv "${sift_stats}" "${downsampled_wm_fod_norm}" "${sift_weights_npy}"
    ${mrtrix_dir}/tcksift2 ${threading} -info "${tracks}" -act "${freesurfer_5tt}" -config NPYFloatMaxSavePrecision 16 \
                           -csv "${sift_stats}" "${wm_fod_norm}" "${sift_weights_npy}"
fi

# sample metrics along streamlines (~4min) -> can be reduced by not using precise
streamline_length_npy="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_length.npy"
streamline_mean_fa_npy="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_FA_mean.npy"
streamline_mean_md_npy="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_1000xMD_mean.npy"
streamline_mean_mo_npy="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_MO_mean.npy"
streamline_mean_s0_npy="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_0.001xS0_mean.npy"
streamline_mean_icvf_npy="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_NODDI_ICVF_mean.npy"
streamline_mean_isovf_npy="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_NODDI_ISOVF_mean.npy"
streamline_mean_od_npy="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_NODDI_OD_mean.npy"
if [ ! -f ${streamline_length_npy} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Sampling metrics along tracks"
    # length
    ${mrtrix_dir}/tckstats ${threading} -info -config NPYFloatMaxSavePrecision 16 -dump \
                           "${streamline_length_npy}" "${tracks}"
    # FA
    ${mrtrix_dir}/tcksample ${threading} -precise -info -config NPYFloatMaxSavePrecision 16 -stat_tck mean \
                            "${tracks}" "${dmri_dir}/dti_FA.nii.gz" "${streamline_mean_fa_npy}"
    # MD
    ${mrtrix_dir}/mrcalc "${dmri_dir}/dti_MD.nii.gz" 1000 -mult - | ${mrtrix_dir}/tcksample ${threading} -precise \
                         -info -config NPYFloatMaxSavePrecision 16 -stat_tck mean "${tracks}" - "${streamline_mean_md_npy}"
    # MO
    ${mrtrix_dir}/tcksample ${threading} -precise -info -config NPYFloatMaxSavePrecision 16 -stat_tck mean \
                            "${tracks}" "${dmri_dir}/dti_MO.nii.gz" "${streamline_mean_mo_npy}"
    # S0
    ${mrtrix_dir}/mrcalc "${dmri_dir}/dti_S0.nii.gz" 0.001 -mult - | ${mrtrix_dir}/tcksample ${threading} -precise \
                         -info -config NPYFloatMaxSavePrecision 16 -stat_tck mean "${tracks}" - "${streamline_mean_s0_npy}"
    # ICVF
    ${mrtrix_dir}/tcksample ${threading} -precise -info -config NPYFloatMaxSavePrecision 16 -stat_tck mean \
                            "${tracks}" "${dmri_dir}/NODDI_ICVF.nii.gz" "${streamline_mean_icvf_npy}"
    # ISOVF
    ${mrtrix_dir}/tcksample ${threading} -precise -info -config NPYFloatMaxSavePrecision 16 -stat_tck mean \
                            "${tracks}" "${dmri_dir}/NODDI_ISOVF.nii.gz" "${streamline_mean_isovf_npy}"
    # OD
    ${mrtrix_dir}/tcksample ${threading} -precise -info -config NPYFloatMaxSavePrecision 16 -stat_tck mean \
                            "${tracks}" "${dmri_dir}/NODDI_OD.nii.gz" "${streamline_mean_od_npy}"
fi

# Convert to float16 NPY binaries (~6sec)
endpoints_npy="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/endpoints/tracks_${streamlines}_endpoints.npy"
mkdir -p "${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/endpoints"
if [ ! -f ${endpoints_npy} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Converting endpoints to .npy binaries (float16)"
    python3 "${script_dir}/python/save_endpoints_as_npy.py" "${endpoints}" "${endpoints_npy}"
fi

echo -e "${GREEN}[INFO]${NC} `date`: Finished tractography for: ${ukb_subject_id}_${ukb_instance}"
