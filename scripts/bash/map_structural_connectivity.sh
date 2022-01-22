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
atlas_name=$6

mrtrix_dir="${main_dir}/lib/mrtrix3/bin"
script_dir="${main_dir}/scripts"
template_dir="${main_dir}/data/templates"
temporary_dir="${main_dir}/data/temporary"

fsaverage_dir="${template_dir}/freesurfer/fsaverage"
dmri_dir="${ukb_subjects_dir}/${ukb_subject_id}_${ukb_instance}/dMRI/dMRI"

threading="-nthreads 0"

atlas_file="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/atlases/native.fMRI_space.${atlas_name}.nii.gz"

echo -e "${GREEN}[INFO]${NC} `date`: Starting structural connectivity mapping for: ${ukb_subject_id}_${ukb_instance} on ${atlas_name}"

# Transform atlas to dwi space (~1sec)
atlas_dwi="${dmri_dir}/native.dMRI_space.${atlas_name}.nii.gz"
transform_DWI_T1="${dmri_dir}/diff2struct_mrtrix.txt"
if [ ! -f ${atlas_dwi} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Transforming atlas to dMRI space"
    mrtransform "${atlas_file}" "${atlas_dwi}" -linear "${transform_DWI_T1}" -inverse ${threading} -info
fi

# Convert atlas to mrtrix format (~1sec)
atlas_dwi_retyped="${dmri_dir}/native.dMRI_space.retyped.${atlas_name}.mif"
atlas_dwi_converted="${dmri_dir}/native.dMRI_space.converted.${atlas_name}.mif"
color_lut="${temporary_dir}/subjects/${ukb_subject_id}_${ukb_instance}/atlases/${atlas_name}.ColorLUT.txt"
color_lut_converted="${dmri_dir}/${atlas_name}.ColorLUT.txt"
if [ ! -f ${atlas_dwi_converted} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Coverting atlas with labelconvert"
    mrconvert ${threading} -info -datatype uint32 "${atlas_dwi}" "${atlas_dwi_retyped}"
    tail -n +2 "${color_lut}" > "${color_lut_converted}"
    labelconvert "${atlas_dwi_retyped}" "${color_lut}" "${color_lut_converted}" "${atlas_dwi_converted}" ${threading} -info
fi

# Compute connectivity for different measures extracted (~1sec)
tracks="${dmri_dir}/tracks_${streamlines}.tck"
sift_weights="${dmri_dir}/sift_weights.txt"
streamline_mean_fa="${dmri_dir}/streamline_metric_FA_mean.txt"
streamline_mean_md="${dmri_dir}/streamline_metric_MD_mean.txt"
streamline_mean_mo="${dmri_dir}/streamline_metric_MO_mean.txt"
streamline_mean_s0="${dmri_dir}/streamline_metric_S0_mean.txt"
streamline_mean_icvf="${dmri_dir}/streamline_metric_NODDI_ICVF_mean.txt"
streamline_mean_isovf="${dmri_dir}/streamline_metric_NODDI_ISOVF_mean.txt"
streamline_mean_od="${dmri_dir}/streamline_metric_NODDI_OD_mean.txt"
out_assignments="${dmri_dir}/out_assignments_${streamlines}.tck"
streamline_count="${dmri_dir}/connectome_streamline_count_${streamlines}.csv"
sift2_fbc="${dmri_dir}/connectome_sift2_fbc_${streamlines}.csv"
mean_length="${dmri_dir}/connectome_mean_length_${streamlines}.csv"
mean_fa="${dmri_dir}/connectome_mean_FA_${streamlines}.csv"
mean_md="${dmri_dir}/connectome_mean_MD_${streamlines}.csv"
mean_mo="${dmri_dir}/connectome_mean_MO_${streamlines}.csv"
mean_s0="${dmri_dir}/connectome_mean_S0_${streamlines}.csv"
mean_icvf="${dmri_dir}/connectome_mean_NODDI_ICVF_${streamlines}.csv"
mean_isovf="${dmri_dir}/connectome_mean_NODDI_ISOVF_${streamlines}.csv"
mean_od="${dmri_dir}/connectome_mean_NODDI_OD_${streamlines}.csv"
if [ ! -f ${out_assignments} ]; then
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from streamline count"
    tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -out_assignments \
    		       "${out_assignments}" "${tracks}" "${atlas_dwi_converted}" "${streamline_count}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from SIFT2 Fiber Bundle Capacity (FBC)"
    tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -tck_weights_in \
                   "${sift_weights}" "${tracks}" "${atlas_dwi_converted}" "${sift2_fbc}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from mean fiber length"
    tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -scale_length \
                   -stat_edge mean "${tracks}" "${atlas_dwi_converted}" "${mean_length}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from fractional anisotropy (FA)"
    tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -tck_weights_in \
                   "${streamline_mean_fa}" -stat_edge mean "${tracks}" "${atlas_dwi_converted}" "${mean_fa}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from mean diffusivity (MD)"
    tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -tck_weights_in \
                   "${streamline_mean_md}" -stat_edge mean "${tracks}" "${atlas_dwi_converted}" "${mean_md}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from mode of the anisotropy (MO)"
    tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -tck_weights_in \
                   "${streamline_mean_mo}" -stat_edge mean "${tracks}" "${atlas_dwi_converted}" "${mean_mo}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from raw T2 signal (S0)"
    tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -tck_weights_in \
                   "${streamline_mean_s0}" -stat_edge mean "${tracks}" "${atlas_dwi_converted}" "${mean_s0}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from NODDI intra-cellular volume fraction (NODDI_ICVF)"
    tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -tck_weights_in \
                   "${streamline_mean_icvf}" -stat_edge mean "${tracks}" "${atlas_dwi_converted}" "${mean_icvf}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from NODDI isotropic volume fraction (NODDI_ISOVF)"
    tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -tck_weights_in \
                   "${streamline_mean_isovf}" -stat_edge mean "${tracks}" "${atlas_dwi_converted}" "${mean_isovf}"
                   
    echo -e "${GREEN}[INFO]${NC} `date`: Computing connectomes from NODDI orientation dispersion index (NODDI_OD)"
    tck2connectome ${threading} -info -symmetric -assignment_radial_search 4 -tck_weights_in \
                   "${streamline_mean_od}" -stat_edge mean "${tracks}" "${atlas_dwi_converted}" "${mean_od}"
fi

