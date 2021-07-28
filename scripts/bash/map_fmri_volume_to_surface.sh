#!/bin/bash

# This script can be used to map fMRI data from volume to cifti.
# The script tries to mimic the HCP minimal pipeline to achieve this goal.
# 
# Helpful resources:
# https://github.com/Washington-University/HCPpipelines

# files directory
# modify this to refere to where the subject data is stored at
# the ralative maps may need to be redefined to apply to UKB directory structure
fdir='/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/fMRI/testing fMRI vol2surf'


# First generate a midthickness surface as UKB does not provide it. (took ~10mins/hemisphere on my PC)
# Method from:
# https://neurostars.org/t/midthickness-for-fsaverage/16676
# change directory to freesurfer surf dir if needed (the white, pial,
# sphere, and thickness files better be in the same dir)
left_native_white_fs="${fdir}/lh.white"
mris_expand -thickness "${left_native_white_fs}" 0.5 graymid
right_native_white_fs="${fdir}/rh.white"
mris_expand -thickness "${right_native_white_fs}" 0.5 graymid
