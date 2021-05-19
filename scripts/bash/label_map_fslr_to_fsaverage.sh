#!/bin/bash

# This script can be used to map the HCP parcellation from the fsLR surface
# to freesurfer native surface.
# 
# Helpful resources:
# https://figshare.com/articles/dataset/HCP-MMP1_0_projected_on_fsaverage/3498446?file=5528816
# https://www.mail-archive.com/hcp-users%40humanconnectome.org/msg02890.html
# https://www.mail-archive.com/hcp-users%40humanconnectome.org/msg02467.html
# https://github.com/Washington-University/HCPpipelines/tree/master/global/templates/standard_mesh_atlases


# Other considerations...
# There are two atlas glasser files (parcellation, validation), the parcellation file is used in this code.


# files directory
# modify this to refere to where the subject data is stored at
# the ralative maps may need to be redefined to apply to UKB directory structure
fdir='/home/sina/Documents/Research/Datasets/glasser annot/my way/files'


# convert glasser label files to label.gii format
atlas_label="${fdir}/Q1-Q6_RelatedParcellation210.CorticalAreas_dil_Final_Final_Areas_Group_Colors.32k_fs_LR.dlabel.nii"
left_atlas_gii="${fdir}/Q1-Q6_RelatedParcellation210.L.CorticalAreas_dil_Final_Final_Areas_Group_Colors.32k_fs_LR.label.gii"
right_alas_gii="${fdir}/Q1-Q6_RelatedParcellation210.R.CorticalAreas_dil_Final_Final_Areas_Group_Colors.32k_fs_LR.label.gii"
wb_command -cifti-separate "${atlas_label}" COLUMN -label CORTEX_LEFT "${left_atlas_gii}"
wb_command -cifti-separate "${atlas_label}" COLUMN -label CORTEX_RIGHT "${right_alas_gii}"


# convert fresurfer native spheres to surf.gii format
left_native_sphere_fs="${fdir}/lh.sphere"
left_native_sphere_gii="${fdir}/lh.sphere.surf.gii"
mris_convert "${left_native_sphere_fs}" "${left_native_sphere_gii}"
right_native_sphere_fs="${fdir}/rh.sphere"
right_native_sphere_gii="${fdir}/rh.sphere.surf.gii"
mris_convert "${right_native_sphere_fs}" "${right_native_sphere_gii}"

# sanity check by conversion of fresurfer native pial to surf.gii format
left_native_pial_fs="${fdir}/lh.pial"
left_native_pial_gii="${fdir}/lh.pial.surf.gii"
mris_convert "${left_native_pial_fs}" "${left_native_pial_gii}"
right_native_pial_fs="${fdir}/rh.pial"
right_native_pial_gii="${fdir}/rh.pial.surf.gii"
mris_convert "${right_native_pial_fs}" "${right_native_pial_gii}"


# surface-sphere-project-unproject
# used to map the native fsaverage space to the fsLR space before resampling
left_fsavg_164k="${fdir}/fsaverage.L.sphere.164k_fs_L.surf.gii"
left_fsavg_164k_to_fsLR="${fdir}/fs_L-to-fs_LR_fsaverage.L_LR.spherical_std.164k_fs_L.surf.gii"
left_native_to_fsLR="${fdir}/lh.sphere.fs_L-to-fs_LR_fsaverage.L_LR.spherical_std.164k_fs_L.surf.gii"
wb_command -surface-sphere-project-unproject "${left_native_sphere_gii}/" "${left_fsavg_164k}" "${left_fsavg_164k_to_fsLR}" "${left_native_to_fsLR}"
right_fsavg_164k="${fdir}/fsaverage.R.sphere.164k_fs_R.surf.gii"
right_fsavg_164k_to_fsLR="${fdir}/fs_R-to-fs_LR_fsaverage.R_LR.spherical_std.164k_fs_R.surf.gii"
right_native_to_fsLR="${fdir}/rh.sphere.fs_R-to-fs_LR_fsaverage.R_LR.spherical_std.164k_fs_R.surf.gii"
wb_command -surface-sphere-project-unproject "${right_native_sphere_gii}/" "${right_fsavg_164k}" "${right_fsavg_164k_to_fsLR}" "${right_native_to_fsLR}"


# label-resample
# used to resample the original atlas in fs-LR to the native surface
left_fsLR32k_gii="${fdir}/L.sphere.32k_fs_LR.surf.gii"
left_native_atlas_gii="${fdir}/native.Q1-Q6_RelatedParcellation210.L.CorticalAreas_dil_Final_Final_Areas_Group_Colors.32k_fs_LR.label.gii"
wb_command -label-resample "${left_atlas_gii}" "${left_fsLR32k_gii}" "${left_native_to_fsLR}" BARYCENTRIC "${left_native_atlas_gii}"
right_fsLR32k_gii="${fdir}/R.sphere.32k_fs_LR.surf.gii"
right_native_atlas_gii="${fdir}/native.Q1-Q6_RelatedParcellation210.R.CorticalAreas_dil_Final_Final_Areas_Group_Colors.32k_fs_LR.label.gii"
wb_command -label-resample "${right_atlas_gii}" "${right_fsLR32k_gii}" "${right_native_to_fsLR}" BARYCENTRIC "${right_native_atlas_gii}"

