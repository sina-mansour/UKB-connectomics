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
    main_dir, ukb_subjects_dir, ukb_subject_id, ukb_instance = sys.argv[1:]

    template_dir = "{}/data/templates".format(main_dir)
    temporary_dir = "{}/data/temporary".format(main_dir)
    output_dir = "{}/data/output".format(main_dir)

    # load the brain mask for global signal computation
    brain_mask = nib.load('{}/{}_{}/fMRI/rfMRI.ica/mask.nii.gz'.format(ukb_subjects_dir, ukb_subject_id, ukb_instance))

    # load the ica clean fMRI
    clean_fmri = nib.load('{}/{}_{}/fMRI/rfMRI.ica/filtered_func_data_clean.nii.gz'.format(ukb_subjects_dir, ukb_subject_id, ukb_instance))

    # compute the global signal
    global_signal_fmri = pd.DataFrame(
        [['global_signal'] + list(np.mean(clean_fmri.get_fdata()[brain_mask.get_fdata() == 1], axis=0))],
        columns=['label_name'] + ['timepoint_{}'.format(x) for x in range(clean_fmri.shape[-1])],
    )

    # write out the resulting time-series in a csv
    global_signal_fmri.to_csv(
        ensure_dir('{}/subjects/{}_{}/fMRI/fMRI.global_signal.csv.gz'.format(temporary_dir, ukb_subject_id, ukb_instance)),
        index=False
    )
