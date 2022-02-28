# script made from notebook codes to save MRtrix output metric files as float16 NPY binaries

import os
import sys
import time
import datetime
import numpy as np


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
    input_metric, output_file, multiplier = sys.argv[1:]

    # read metric
    metric = np.loadtxt(input_metric)

    # write as npy (float16 precision)
    np.save(ensure_dir(output_file), (metric * float(multiplier)).astype(np.float16))
