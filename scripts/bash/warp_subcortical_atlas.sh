#!/bin/bash

# This script can be used to warp the melbourne subcortical atlas from the MNI space to subject's native space:
# 
# Helpful resources:
# https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FNIRT/UserGuide#Now_what.3F_--_applywarp.21

# the applywarp command can be used to warp images from the native space to MNI:
# applywarp --ref=T1/T1_brain_to_MNI.nii.gz --in=T1/T1_brain.nii.gz --warp=T1/transforms/T1_to_MNI_warp_coef.nii.gz --out=T1/T1_brain_test_MNI_warped.nii.gz 

# next, the provided warp file needs to be reversed in order to be used to warp from MNI to native: (the command takes nearly an hour to execute)
invwarp --ref=T1/T1_brain.nii.gz --warp=T1/transforms/T1_to_MNI_warp_coef.nii.gz --out=T1/transforms/MNI_to_T1_inversed_warp_coef.nii.gz

# having computed the inverse warp, we could use it to warp from MNI to native space
# applywarp --ref=T1/T1_brain.nii.gz --in=T1/T1_brain_to_MNI.nii.gz --warp=T1/transforms/MNI_to_T1_inversed_warp_coef.nii.gz --out=T1/T1_brain_to_MNI_warped_back_to_native.nii.gz 

# mainly, we'll use the inverse warp to transform the subcortical atlas to native space
applywarp --ref=T1/T1_brain.nii.gz --in=Tian_Subcortex_S3_3T.nii.gz --warp=T1/transforms/MNI_to_T1_inversed_warp_coef.nii.gz --out=native_Tian_Subcortex_S3_3T.nii.gz  --interp=nn

# This native parcellation should now be resampled to the fmri space
mri_vol2vol --mov native_Tian_Subcortex_S3_3T.nii.gz --targ fMRI/rfMRI.ica/mean_func.nii.gz --interp nearest --regheader --o native_Tian_Subcortex_S3_3T_func_space.nii.gz
