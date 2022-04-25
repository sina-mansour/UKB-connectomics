# script made from notebook codes to save MRtrix output metric files as float16 NPY binaries

import os
import sys
import numpy as np


def ensure_dir(file_name):
    os.makedirs(os.path.dirname(file_name), exist_ok=True)
    return file_name


if __name__ == '__main__':
    # sys.argv
    input_csv, output_npy = sys.argv[1:]

    # read metric
    content = np.loadtxt(input_csv, dtype=np.float32, delimiter=',')

    # write as npy (float16 precision)
    np.save(ensure_dir(output_npy), content.astype(np.float32))
