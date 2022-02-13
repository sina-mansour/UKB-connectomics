# script made from the notebook codes

import os
import sys
import time
import datetime
import numpy as np
import pandas as pd
import nibabel as nib
from scipy import spatial
from nibabel import freesurfer


def ensure_dir(file_name):
    os.makedirs(os.path.dirname(file_name), exist_ok=True)
    return file_name


def time_str(mode='abs', base=None):
    if mode == 'rel':
        return str(datetime.timedelta(seconds=(time.time() - base)))
    if mode == 'raw':
        return time.time()
    if mode == 'abs':
        return time.asctime(time.localtime(time.time()))


if __name__ == '__main__':
    # sys.argv
    main_dir, ukb_subjects_dir, ukb_subject_id, ukb_instance, atlas_1_name, atlas_2_name = sys.argv[1:]

    template_dir = "{}/data/templates".format(main_dir)
    temporary_dir = "{}/data/temporary".format(main_dir)
    output_dir = "{}/data/output".format(main_dir)

    # combine two atlases and generate a new label table
    # this is mainly used to add a subcortical atlas (atlas_2) to a cortical volumetric brain label (atlas_1)
    #
    # in case a voxel has non-zero labels in both atlases, atlas_1 label will be used.

    # load cortical label indices
    cortical_labels = pd.DataFrame(
        np.genfromtxt(
            '{}/atlases/labels/{}.ColorLUT.txt'.format(template_dir, atlas_1_name),
            dtype='str'
        ),
        columns=['index', 'label_name', 'R', 'G', 'B', 'A'],
    ).astype(
        dtype={
            "index": "int",
            "label_name": "str",
            "R": "int",
            "G": "int",
            "B": "int",
            "A": "int",
        }
    )

    # load native atlases
    atlas_1 = f'{ukb_subjects_dir}/{ukb_subject_id}_{ukb_instance}/dMRI/dMRI/atlases/native.dMRI_space.{atlas_1_name}.nii.gz'
    atlas_2 = f'{ukb_subjects_dir}/{ukb_subject_id}_{ukb_instance}/dMRI/dMRI/atlases/native.dMRI_space.{atlas_2_name}.nii.gz'
    atlas_1_image = nib.as_closest_canonical(nib.load(atlas_1))
    atlas_2_image = nib.as_closest_canonical(nib.load(atlas_2))

    # load atlas data
    atlas_1_data = atlas_1_image.get_fdata()
    atlas_2_data = atlas_2_image.get_fdata()

    # mask and shift atlas_2 labels
    data_mask = (atlas_1_data == 0)
    shift_mask = (atlas_2_data > 0)
    shift_value = cortical_labels['index'].max()
    atlas_2_data_masked_shifted = np.multiply((shift_mask & data_mask), (atlas_2_data + shift_value))

    combined_atlas_data = atlas_1_data + atlas_2_data_masked_shifted

    # store combined atlas
    nib.save(
        nib.Nifti1Image(combined_atlas_data, atlas_1_image.affine, atlas_1_image.header),
        ensure_dir(f'{ukb_subjects_dir}/{ukb_subject_id}_{ukb_instance}/dMRI/dMRI/atlases/combinations/native.dMRI_space.{atlas_1_name}+{atlas_2_name}.nii.gz')
    )

    # generate new colorLUTs (Note: colorLUTs generated in ipython notebook)
