import os
import sys
import time
import datetime
import pandas as pd


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
    bulk_dir, bulklist = sys.argv[1:]

    # break comma separated bulk names from bulk list
    bulks = bulklist.split(',')

    # read all bulks
    bulkstore = {}
    subjects = {}
    fields = {}
    instances = {}
    subject_instances = {}
    for bulk in bulks:
        bulkstore[bulk] = pd.read_csv(
            '{}/{}.bulk'.format(bulk_dir, bulk),
            header=None,
            delim_whitespace=True,
            dtype=str
        )
        subjects[bulk] = bulkstore[bulk][0]
        fields[bulk] = bulkstore[bulk][1][0].split('_')[0]
        instances[bulk] = bulkstore[bulk][1].str.split('_', 1, expand=True)[1]
        subject_instances[bulk] = set(subjects[bulk] + ' ' + instances[bulk])

    # compute the intersection
    subject_instance_intersection = list(set.intersection(*[subject_instances[bulk] for bulk in bulks]))
    subject_instance_intersection.sort()

    # write output to file
    with open('{}/{}.combined'.format(bulk_dir, bulklist), 'w') as outfile:
        for x in subject_instance_intersection:
            outfile.write('{}\n'.format(x))
