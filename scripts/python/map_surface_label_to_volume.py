# script made from the notebook codes

import numpy as np
import pandas as pd
import nibabel as nib
from scipy import spatial
from nibabel import freesurfer


# load the pial and white surfaces for left and right hemispheres
#
# each loaded object is a python tuple containing two elements:
#     1. the coordinates of all vertices
#     2. the triangle information of the mesh

lh_pial_surf = freesurfer.read_geometry('/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/FreeSurfer/surf/lh.pial')
lh_white_surf = freesurfer.read_geometry('/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/FreeSurfer/surf/lh.white')

rh_pial_surf = freesurfer.read_geometry('/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/FreeSurfer/surf/rh.pial')
rh_white_surf = freesurfer.read_geometry('/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/FreeSurfer/surf/rh.white')


# Now let's load the surface atlas mapped to each surface
#
# each loaded object is a python tuple containing 3 elements:
#     1. A list of integers indicating the label of each vertex
#     2. A table for the color of each label (r, g, b, t, colortable array id)
#     3. A list names of the lables

lh_glasser_annot = freesurfer.read_annot('/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/FreeSurfer/label/lh.native.glasser.annot')
rh_glasser_annot = freesurfer.read_annot('/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/FreeSurfer/label/rh.native.glasser.annot')


# Finally we need to load the ribbon mask to use as a reference for voxels to be labeled (only label voxels in the cortical ribbon)
#
# The ribbon file can be read using nibabel. The saved object is an MGHImage object containing the affine matrix, as well as the labels in a 3d data matrix
# Check https://nipy.org/nibabel/reference/nibabel.freesurfer.html#nibabel.freesurfer.mghformat.MGHImage
#
# Label numbers are from the FreeSurferColorLUT (https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/AnatomicalROI/FreeSurferColorLUT) lookup table and has 5 values:
#     0: Unknown
#     2: Left-Cerebral-White-Matter
#     3: Left-Cerebral-Cortex
#     41: Right-Cerebral-White-Matter
#     42: Right-Cerebral-Cortex

id_to_label = {
    0: 'Unknown',
    2: 'Left-Cerebral-White-Matter',
    3: 'Left-Cerebral-Cortex',
    41: 'Right-Cerebral-White-Matter',
    42: 'Right-Cerebral-Cortex',
}

label_id = {id_to_label[x]: x for x in id_to_label}

ribbon = nib.load('/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/FreeSurfer/mri/ribbon.mgz')

# Given the potential problems with mgz files, mainly the overflow of uint8, I tried converting the original mgz to nii
# the following command was used:
# mri_convert --in_type mgz --out_type nii --out_orientation RAS FreeSurfer/mri/ribbon.mgz FreeSurfer/mri/ribbon.nii.gz

ribbonnii = nib.load('/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/FreeSurfer/mri/ribbon.nii.gz')


# We'll use kdtree to store the coordinates in data structure to query for nearest neighbor
#
# One kdtree per hemisphere

lh_pial_xyz = lh_pial_surf[0]
lh_white_xyz = lh_white_surf[0]
lh_xyz = np.vstack([lh_pial_xyz, lh_white_xyz])
lh_white_kdtree = spatial.KDTree(lh_white_xyz)
lh_pial_kdtree = spatial.KDTree(lh_pial_xyz)
lh_kdtree = spatial.KDTree(lh_xyz)

rh_pial_xyz = rh_pial_surf[0]
rh_white_xyz = rh_white_surf[0]
rh_xyz = np.vstack([rh_pial_xyz, rh_white_xyz])
rh_white_kdtree = spatial.KDTree(rh_white_xyz)
rh_pial_kdtree = spatial.KDTree(rh_pial_xyz)
rh_kdtree = spatial.KDTree(rh_xyz)


# create a copy of the ribbon label file to overwrite
glasser_labels = (ribbon.get_fdata().copy() * 0).astype(np.uint)

# extract the indices of voxels in the cortical ribbon
lh_cortex_ijk = np.array(np.where(ribbon.get_fdata() == label_id['Left-Cerebral-Cortex'])).T
rh_cortex_ijk = np.array(np.where(ribbon.get_fdata() == label_id['Right-Cerebral-Cortex'])).T

# use the affine transformation to get to xyz coordinates of the voxels
lh_cortex_xyz = nib.affines.apply_affine(ribbon.header.get_vox2ras_tkr(), lh_cortex_ijk)
rh_cortex_xyz = nib.affines.apply_affine(ribbon.header.get_vox2ras_tkr(), rh_cortex_ijk)

# querry each voxel's coordinates to find the nearest neighbor on the surfaces (takes a few seconds)
lh_distance, lh_index = lh_kdtree.query(lh_cortex_xyz)
rh_distance, rh_index = rh_kdtree.query(rh_cortex_xyz)

# convert the indices to a surface index (reduce the white matter and pial indices to one)
lh_index_surf = lh_index % (lh_glasser_annot[0].shape[0])
rh_index_surf = rh_index % (rh_glasser_annot[0].shape[0])

# write appropriate labels from glasser atlas to volume
glasser_labels[ribbon.get_fdata() == label_id['Left-Cerebral-Cortex']] = lh_glasser_annot[0][lh_index_surf]
glasser_labels[ribbon.get_fdata() == label_id['Right-Cerebral-Cortex']] = rh_glasser_annot[0][rh_index_surf]

# now write the label into an mgh freesurfer volumetric format
img = nib.nifti1.Nifti1Image(
    glasser_labels,
    ribbon.header.get_vox2ras(),
)

nib.save(
    img,
    '/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/FreeSurfer/mri/glasser.nii.gz'
)

# color lookup table in freesurfer format
np.savetxt(
    '/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/FreeSurfer/mri/glasserColorLUT.txt',
    np.array(
        pd.DataFrame({
            '#No.': np.arange(len(lh_glasser_annot[2])),
            'Label Name': [x.decode('utf8') for x in lh_glasser_annot[2]],
            'R': lh_glasser_annot[1][:, 0],
            'G': lh_glasser_annot[1][:, 1],
            'B': lh_glasser_annot[1][:, 2],
            'A': lh_glasser_annot[1][:, 3],
        })
    ),
    fmt=['%d', '%s', '%d', '%d', '%d', '%d']
)


# color lookup table to be used with the connectome workbench viewer
atlas_labels = [x.decode('utf8') for x in lh_glasser_annot[2]]

with open('/home/sina/Documents/Research/Datasets/UK biobank/sample/1000094/FreeSurfer/mri/glasser_label_list.txt', 'w') as label_list_file:
    for i in range(1, len(lh_glasser_annot[2])):
        label_list_file.write(
            '{}\n{} {} {} {} {}\n'.format(
                atlas_labels[i],
                i,
                lh_glasser_annot[1][i, 0],
                lh_glasser_annot[1][i, 1],
                lh_glasser_annot[1][i, 2],
                (255 - lh_glasser_annot[1][i, 3]),
            )
        )
