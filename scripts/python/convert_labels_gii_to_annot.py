# script to convert label GIFTI files to annot format (to fix the bug encountered with mris_convert)

import sys
import time
import datetime
import numpy as np
import nibabel as nib
from nibabel import freesurfer


def time_str(mode='abs', base=None):
    if mode == 'rel':
        return str(datetime.timedelta(seconds=(time.time() - base)))
    if mode == 'raw':
        return time.time()
    if mode == 'abs':
        return time.asctime(time.localtime(time.time()))


if __name__ == '__main__':
    # sys.argv
    gifti_in, annot_out = sys.argv[1:]

    # read the gifti labels
    gifti = nib.load(gifti_in)

    # construct the complete label set
    labels = [gifti.labeltable.get_labels_as_dict()[x] for x in range(len(gifti.labeltable.labels))]

    # construct ctab
    colors = np.random.default_rng().choice(2**24, len(gifti.labeltable.labels), replace=False)
    ctab = np.c_[(colors // 256**2), ((colors // 256) % 256), (colors % 256), np.zeros(len(gifti.labeltable.labels))]
    ctab[0, :] = [1, 1, 1, 1]

    # write our the annot file (random color ctab)
    freesurfer.write_annot(
        annot_out,
        gifti.darrays[0].data,
        ctab,
        labels,
        fill_ctab=True
    )

    print('{}: \033[0;32m[INFO]\033[0m The gifti file "{}" successfully converted to annot file "{}".'.format(
        time_str(), gifti_in, annot_out)
    )
