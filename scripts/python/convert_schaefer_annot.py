# script to convert Shaefer parcelation annot formats to our desired format

import sys
import time
import datetime
import numpy as np
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
    annot_in_l, annot_in_r, annot_out_l, annot_out_r = sys.argv[1:]

    # read the gifti labels
    in_l = freesurfer.read_annot(annot_in_l)
    in_r = freesurfer.read_annot(annot_in_r)

    # construct the complete label set
    labels = ['???'] + in_l[2][1:] + in_r[2][1:]

    # construct the complete ctab
    # ctab = np.concatenate([np.array([[1, 1, 1, 1, 65793]]), in_l[1][1:], in_r[1][1:]])
    # ctab = np.c_[np.random.choice(256, (len(labels), 3)), np.zeros(len(labels))]
    colors = np.random.default_rng().choice(2**24, len(labels), replace=False)
    ctab = np.c_[(colors // 256**2), ((colors // 256) % 256), (colors % 256), np.zeros(len(labels))]
    ctab[0, :] = [1, 1, 1, 1]

    # writ out the modified annot files (shif right hemisphere label values)

    # write out the left hemisphere's annot file
    freesurfer.write_annot(
        annot_out_l,
        in_l[0],
        ctab,
        labels,
        fill_ctab=True
    )
    lmax = in_l[0].max()
    freesurfer.write_annot(
        annot_out_r,
        np.where(
            (in_r[0] + lmax) == lmax,
            0,
            in_r[0] + lmax
        ),
        ctab,
        labels,
        fill_ctab=True
    )

    print('{}: \033[0;32m[INFO]\033[0m Successfully converted the annot files.'.format(
        time_str())
    )
