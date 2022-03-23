#!/bin/bash

# This script uses the estimated probabilistic tractography streamlines
# to generate connectomes on volumetric native atlases.
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
cortical_atlas_name=$6
subcortical_atlas_name=$7

mrtrix_dir="${main_dir}/lib/mrtrix3/bin"
script_dir="${main_dir}/scripts"
template_dir="${main_dir}/data/templates"
temporary_dir="${main_dir}/data/temporary"

fsaverage_dir="${template_dir}/freesurfer/fsaverage"
dmri_dir="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/dMRI/dMRI"

threading="-nthreads 0"

cortical_atlas_file="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/atlases/native.${cortical_atlas_name}.nii.gz"
subcortical_atlas_file="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/atlases/native.${subcortical_atlas_name}.nii.gz"

echo -e "${GREEN}[INFO]${NC} `date`: Starting structural connectivity mapping for: ${ukb_subject_id}_${ukb_instance} on (cortical: ${cortical_atlas_name}, subcortical: ${subcortical_atlas_name}) atlases."

# Transform atlases to dwi space (~1sec)
cortical_atlas_dwi="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/atlases/native.dMRI_space.${cortical_atlas_name}.nii.gz"
transform_DWI_T1="${dmri_dir}/diff2struct_mrtrix.txt"
mkdir -p "${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/atlases"
if [ ! -f ${cortical_atlas_dwi} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Transforming atlases to dMRI space"
    mkdir -p "${dmri_dir}/atlases/"
    # no need for nearest neighbor given rigid transformation (see issue #19)
    ${mrtrix_dir}/mrtransform "${cortical_atlas_file}" "${cortical_atlas_dwi}" -linear "${transform_DWI_T1}" -inverse \
                -datatype uint32 ${threading} -info
fi
subcortical_atlas_dwi="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/atlases/native.dMRI_space.${subcortical_atlas_name}.nii.gz"
if [ ! -f ${subcortical_atlas_dwi} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Transforming atlases to dMRI space"
    # nearest neighbor mapping as we aim to combine two atlases (see issue #19)
    ${mrtrix_dir}/mrtransform "${subcortical_atlas_file}" "${subcortical_atlas_dwi}" -linear "${transform_DWI_T1}" -inverse -interp nearest \
                -datatype uint32 -template "${cortical_atlas_dwi}" ${threading} -info
fi

# Combine atlases together
combined_atlas_dwi="${dmri_dir}/atlases/combinations/native.dMRI_space.${cortical_atlas_name}+${subcortical_atlas_name}.nii.gz"
if [ ! -f ${combined_atlas_dwi} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Combining the cortical and subcortical atlases in dMRI space"
    # nearest neighbor mapping as we aim to combine two atlases (see issue #19)
    python3 "${script_dir}/python/combine_volumetric_atlases.py" "${main_dir}" "${ukb_subjects_dir}" "${ukb_subject_id}" "${ukb_instance}" "${cortical_atlas_name}" "${subcortical_atlas_name}"
fi

# Compute connectivity for different measures extracted (~1sec)
# tracks="${dmri_dir}/tracks_${streamlines}.tck"
endpoints="${dmri_dir}/tracks_${streamlines}_endpoints.tck"
sift_weights="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/sift_weights.npy"
streamline_length="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_length.npy"
streamline_mean_fa="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_FA_mean.npy"
# streamline_mean_md="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_MD_mean.txt"
# streamline_mean_mo="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_MO_mean.txt"
# streamline_mean_s0="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_S0_mean.txt"
# streamline_mean_icvf="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_NODDI_ICVF_mean.txt"
# streamline_mean_isovf="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_NODDI_ISOVF_mean.txt"
# streamline_mean_od="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/metrics/streamline_metric_NODDI_OD_mean.txt"
streamline_count="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/${cortical_atlas_name}+${subcortical_atlas_name}/connectome_streamline_count_${streamlines}.csv"
sift2_fbc="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/${cortical_atlas_name}+${subcortical_atlas_name}/connectome_sift2_fbc_${streamlines}.csv"
mean_length="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/${cortical_atlas_name}+${subcortical_atlas_name}/connectome_mean_length_${streamlines}.csv"
mean_fa="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/${cortical_atlas_name}+${subcortical_atlas_name}/connectome_mean_FA_${streamlines}.csv"
# mean_md="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/${cortical_atlas_name}+${subcortical_atlas_name}/connectome_mean_MD_${streamlines}.csv"
# mean_mo="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/${cortical_atlas_name}+${subcortical_atlas_name}/connectome_mean_MO_${streamlines}.csv"
# mean_s0="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/${cortical_atlas_name}+${subcortical_atlas_name}/connectome_mean_S0_${streamlines}.csv"
# mean_icvf="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/${cortical_atlas_name}+${subcortical_atlas_name}/connectome_mean_NODDI_ICVF_${streamlines}.csv"
# mean_isovf="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/${cortical_atlas_name}+${subcortical_atlas_name}/connectome_mean_NODDI_ISOVF_${streamlines}.csv"
# mean_od="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/${cortical_atlas_name}+${subcortical_atlas_name}/connectome_mean_NODDI_OD_${streamlines}.csv"
mkdir -p "${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/tractography/connectomes/${cortical_atlas_name}+${subcortical_atlas_name}/"
if [ ! -f ${streamline_count} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from streamline count"
    ${mrtrix_dir}/tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 \
    		       "${endpoints}" "${combined_atlas_dwi}" "${streamline_count}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from SIFT2 Fiber Bundle Capacity (FBC)"
    ${mrtrix_dir}/tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -tck_weights_in \
                   "${sift_weights}" "${endpoints}" "${combined_atlas_dwi}" "${sift2_fbc}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from mean fiber length"
    ${mrtrix_dir}/tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -scale_file \
                   "${streamline_length}" -stat_edge mean "${endpoints}" "${combined_atlas_dwi}" "${mean_length}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from fractional anisotropy (FA)"
    ${mrtrix_dir}/tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -scale_file \
                   "${streamline_mean_fa}" -stat_edge mean "${endpoints}" "${combined_atlas_dwi}" "${mean_fa}"
                   
    # echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from mean diffusivity (MD)"
    # ${mrtrix_dir}/tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -scale_file \
    #                "${streamline_mean_md}" -stat_edge mean "${endpoints}" "${combined_atlas_dwi}" "${mean_md}"
                   
    # echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from mode of the anisotropy (MO)"
    # ${mrtrix_dir}/tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -scale_file \
    #                "${streamline_mean_mo}" -stat_edge mean "${endpoints}" "${combined_atlas_dwi}" "${mean_mo}"
                   
    # echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from raw T2 signal (S0)"
    # ${mrtrix_dir}/tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -scale_file \
    #                "${streamline_mean_s0}" -stat_edge mean "${endpoints}" "${combined_atlas_dwi}" "${mean_s0}"
                   
    # echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from NODDI intra-cellular volume fraction (NODDI_ICVF)"
    # ${mrtrix_dir}/tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -scale_file \
    #                "${streamline_mean_icvf}" -stat_edge mean "${endpoints}" "${combined_atlas_dwi}" "${mean_icvf}"
                   
    # echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from NODDI isotropic volume fraction (NODDI_ISOVF)"
    # ${mrtrix_dir}/tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -scale_file \
    #                "${streamline_mean_isovf}" -stat_edge mean "${endpoints}" "${combined_atlas_dwi}" "${mean_isovf}"
                   
    # echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from NODDI orientation dispersion index (NODDI_OD)"
    # ${mrtrix_dir}/tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -scale_file \
    #                "${streamline_mean_od}" -stat_edge mean "${endpoints}" "${combined_atlas_dwi}" "${mean_od}"
fi

echo -e "${GREEN}[INFO]${NC} `date`: Finished structural connectivity mapping for: ${ukb_subject_id}_${ukb_instance} on ${atlas_name}"
