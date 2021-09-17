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
    left_labels = [x.decode() for x in in_l[2]]
    right_labels = [x.decode() for x in in_r[2]]

    # replace lables
    left_labels_dict = {x:i+1 for (i,x) in enumerate(left_labels[1:])}
    left_labels_dict.update({'???':-1})
    left_removes = [x for x in left_labels_dict.values() if x not in np.unique(in_l[0])]

    left_labels_clean = [x for x in left_labels[1:] if left_labels_dict[x] not in left_removes]
    left_label_replace = {left_labels_dict[x]:i+1 for (i,x) in enumerate(left_labels_clean)}
    left_label_replace.update({-1:0})

    right_labels_dict = {x:i+1 for (i,x) in enumerate(right_labels[1:])}
    right_labels_dict.update({'???':-1})
    right_removes = [x for x in right_labels_dict.values() if x not in np.unique(in_l[0])]

    right_labels_clean = [x for x in right_labels[1:] if right_labels_dict[x] not in right_removes]
    right_label_replace = {right_labels_dict[x]:i+1+len(left_labels_clean) for (i,x) in enumerate(right_labels_clean)}
    right_label_replace.update({-1:0})

    labels = ['???'] + ['left_{}'.format(x) for x in left_labels_clean] + ['right_{}'.format(x) for x in right_labels_clean]

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
        [left_label_replace[x] for x in in_l[0]],
        ctab,
        labels,
        fill_ctab=True
    )
    freesurfer.write_annot(
        annot_out_r,
        [right_label_replace[x] for x in in_r[0]],
        ctab,
        labels,
        fill_ctab=True
    )

    print('{}: \033[0;32m[INFO]\033[0m Successfully converted the annot files.'.format(
        time_str())
    )
