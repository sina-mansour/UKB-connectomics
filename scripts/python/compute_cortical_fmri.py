# script made from the notebook codes

import os
import sys
import numpy as np
import pandas as pd
import nibabel as nib


def ensure_dir(file_name):
    os.makedirs(os.path.dirname(file_name), exist_ok=True)
    return file_name


if __name__ == '__main__':
    # sys.argv
    main_dir, ukb_subjects_dir, ukb_subject_id, ukb_instance, atlas_name = sys.argv[1:]

    template_dir = "{}/data/templates".format(main_dir)
    temporary_dir = "{}/data/temporary".format(main_dir)
    output_dir = "{}/data/output".format(main_dir)

    # load the volumetric atlas
    cortical_atlas = nib.load('{}/subjects/{}_{}/atlases/native.fMRI_space.{}.nii.gz'.format(temporary_dir, ukb_subject_id, ukb_instance, atlas_name))

    # load names of all labels from the color lookup table
    cortical_labels = pd.DataFrame(
        np.genfromtxt(
            '{}/atlases/labels/{}.ColorLUT.txt'.format(template_dir, atlas_name),
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

    # load the ica clean fMRI
    clean_fmri = nib.load('{}/{}_{}/fMRI/rfMRI.ica/filtered_func_data_clean.nii.gz'.format(ukb_subjects_dir, ukb_subject_id, ukb_instance))

    # extract label names
    cortical_atlas_fmri = cortical_labels[['index', 'label_name']][cortical_labels['label_name'] != '???'].copy()

    # Here, we'll average fmri signal over every label from atlas
    cortical_atlas_fmri = pd.concat(
        [
            cortical_atlas_fmri['label_name'],
            pd.DataFrame(
                np.array(
                    [
                        np.mean(clean_fmri.get_fdata()[cortical_atlas.get_fdata() == x['index']], axis=0)
                        for (i, x) in cortical_atlas_fmri.iterrows()
                    ]
                ),
                index=cortical_atlas_fmri.index,
                columns=['timepoint_{}'.format(x) for x in range(clean_fmri.shape[-1])],
            )
        ],
        axis=1
    )

    # write out the resulting time-series in a csv
    cortical_atlas_fmri.to_csv(
        ensure_dir('{}/subjects/{}_{}/fMRI/fMRI.{}.csv.gz'.format(temporary_dir, ukb_subject_id, ukb_instance, atlas_name)),
        index=False
    )
