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

    # load the subcortical atlas from file
    subcortical_atlas = nib.load('{}/subjects/{}_{}/atlases/native.fMRI_space.{}.nii.gz'.format(temporary_dir, ukb_subject_id, ukb_instance, atlas_name))

    # load the atlas label names from txt file
    subcortical_labels = pd.DataFrame(
        ['???'] + list(np.genfromtxt(
            '{}/atlases/{}_label.txt'.format(template_dir, atlas_name),
            dtype='str'
        )),
        columns=['label_name'],
    ).astype(
        dtype={
            "label_name": "str",
        }
    )
    subcortical_labels['index'] = subcortical_labels.index

    # load the ica clean fMRI
    clean_fmri = nib.load('{}/{}_{}/fMRI/rfMRI.ica/filtered_func_data_clean.nii.gz'.format(ukb_subjects_dir, ukb_subject_id, ukb_instance))

    # extract label names, excluding ???
    subcortical_atlas_fmri = subcortical_labels[['index', 'label_name']][subcortical_labels['label_name'] != '???'].copy()

    # Here, we'll average fmri signal over every label from atlas
    subcortical_atlas_fmri = pd.concat(
        [
            subcortical_atlas_fmri['label_name'],
            pd.DataFrame(
                np.array(
                    [
                        np.mean(clean_fmri.get_fdata()[subcortical_atlas.get_fdata() == x['index']], axis=0)
                        for (i, x) in subcortical_atlas_fmri.iterrows()
                    ]
                ),
                index=subcortical_atlas_fmri.index,
                columns=['timepoint_{}'.format(x) for x in range(clean_fmri.shape[-1])],
            )
        ],
        axis=1
    )

    # write out the resulting time-series in a csv
    subcortical_atlas_fmri.to_csv(
        ensure_dir('{}/subjects/{}_{}/fMRI/fMRI.{}.csv.gz'.format(temporary_dir, ukb_subject_id, ukb_instance, atlas_name)),
        index=False
    )
