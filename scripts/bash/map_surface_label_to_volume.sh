#!/bin/bash

# This script can be used to map a .annot label from surface to ribbon.
# 
# Helpful resources:
# https://surfer.nmr.mgh.harvard.edu/fswiki/fill%25annot%25volume

# files directory
# modify this to refere to where the subject data is stored at
# the ralative maps may need to be redefined to apply to UKB directory structure
fdir='/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094'

# change freesurfer subject dir
SUBJECTS_DIR="${fdir}"

# fill the cortical ribbon with glasser labels
# 
# this first method did not work as expected
# mri_aparc2aseg --new-ribbon --s FreeSurfer --annot "native.glasser" --o "FreeSurfer/mri/native.glasser+aseg.mgz"
# 
# this second method does a beeter job, but is not perfect, takes more than 10 min to finish, and the final labels are not perfect (missing voxels, labels outside of the ribbon)
# mri_label2vol --annot ./FreeSurfer/label/lh.native.glasser.annot --o lh.native.glasser.proj0.3.mgz --proj frac 0 1 0.1 --fillthresh .3 --subject FreeSurfer --hemi lh --regheader ./FreeSurfer/mri/brain.mgz --temp ./FreeSurfer/mri/lh.ribbon.mgz

# 
# We've decided to try implementing a python script to achieve this functionality (map_surface_label_to_volume.py)
# 